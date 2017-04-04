require_relative 'matcher'
require 'json'

class RpXface
  def self.setup(args)
    args.merge!({
        id: plsql.rp_available_reports_seq.nextval,
        dsn: 'dsn',
        db_unit: 'db_unit',
        created_at: Date.today,
        updated_at: Date.today,
        batch_size: 50,
        header_kind: 'D',
        money_format: '##.00'
      })
      args = args.tap do |p|
        (1..5).each do |i|
          s = "param#{i}"
          s_name = "#{s}_name".to_sym
          s_type = "#{s}_type".to_sym
          if p[s.to_sym].instance_of?(Hash)
            param = {}
            param[s_name] = p[s.to_sym][:name]
            param[s_type] = p[s.to_sym][:type]
            p[s.to_sym] = JSON.generate(param)
          end
        end
      end  
    plsql.rp_available_reports.insert(args)
  end
  
  def self.get_param(param)
    return {pri_data_type: 'text', pri_text_value: param, pri_date_value: nil, pri_number_value: nil} if param.is_a?(String)
    return {pri_data_type: 'date', pri_text_value: nil, pri_date_value: param, pri_number_value: nil} if param.is_a?(Date)
    return {pri_data_type: 'number', pri_text_value: nil, pri_date_value: nil, pri_number_value: param} if param.is_a?(Integer)
  end
  
  def self.schedule_report(name, param1 = nil, param2 = nil, param3 = nil, param4 = nil, param5 = nil, run_at = nil)
    plsql_result = plsql.pk_qg_rp_xface.schedule_report(
    pi_ar_name: name,
    pi_param1: get_param(param1),
    pi_param2: get_param(param2),
    pi_param3: get_param(param3),
    pi_param4: get_param(param4),
    pi_param5: get_param(param5),
    pi_run_at: run_at,
    po_fault_code: nil,
    po_fault_reason: nil
    )
    
    rp_report_id = plsql_result[0]
    fault_code = plsql_result[1][:po_fault_code]
    fault_reason = plsql_result[1][:po_fault_reason]
    
    return {fault_code: fault_code, fault_reason: fault_reason} unless fault_code.nil?
    
    plsql.select(:first, "select * from rp_reports where id = #{rp_report_id}")
  end
end

describe 'pk_qg_rp_xface' do

  context 'schedule report' do
  
    context 'for a report with 5 params' do
      ar1 = {name: '5_SUCCESS', params_cnt: 5, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'date'}, 
             param3: {name: 'p3', type: 'number'}, param4: {name: 'p4', type: 'number'}, param5: {name: 'p5', type: 'text'}}
             
      before(:all) do
        RpXface.setup(ar1)
      end

      context 'passing 5 params matching the definition' do
        it 'should enqueue a report with_state_new' do
          expect(RpXface.schedule_report(ar1[:name], 
            'p1',
            Date.today,
            9,
            8,
            'p5'))
          .to be_correct(ar1).with_status_new
        end
      end
    end
    
    context 'for a report with 4 params' do
      ar2 = {name: '4_SUCCESS', params_cnt: 4, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'date'}, 
             param3: {name: 'p3', type: 'number'}, param4: {name: 'p4', type: 'number'}}

      before(:all) do
        RpXface.setup(ar2)
      end

      context 'passing 4 params matching the report definition' do
        it 'should enqueue a report with_state_new' do
          expect(RpXface.schedule_report(ar2[:name], 
            'p1',
            Date.today,
            9,
            8))
          .to be_correct(ar2).with_status_new
        end
      end
    end
    
    context 'for a report with 3 params' do
      ar3 = {name: '3_SUCCESS', params_cnt: 3, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'date'}, 
            param3: {name: 'p3', type: 'number'}}
            
      before(:all) do
        RpXface.setup(ar3)
      end

      context 'passing 3 params matching the report definition' do
        it 'should enqueue a report with_state_new' do
          expect(RpXface.schedule_report(ar3[:name], 
            'p1',
            Date.today,
            9))
          .to be_correct(ar3).with_status_new
        end
      end
    end
    
    context 'for a report with 2 params' do
      ar4 = {name: '2_SUCCESS', params_cnt: 2, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'date'}}
      
      before(:all) do
        RpXface.setup(ar4)
      end

      context 'passing 2 params matching the report definition' do
        it 'should enqueue a report with_state_new' do
          expect(RpXface.schedule_report(ar4[:name], 
            'p1',
            Date.today))
          .to be_correct(ar4).with_status_new
        end
      end
    end
    
    context 'for a report with 1 param' do
      ar5 = {name: '1_SUCCESS', params_cnt: 1, param1: {name: 'p1', type: 'text'}}
      
      before(:all) do
        RpXface.setup(ar5)
      end
      
      context 'passing 1 param matching the report definition' do
        it 'should enqueue a report with_state_new' do
          expect(RpXface.schedule_report(ar5[:name], 
            'p1'))
          .to be_correct(ar5).with_status_new
        end
      end
    end
    
    context 'for a report with 0 param' do
      ar6 = {name: '0_SUCCESS', params_cnt: 0}
      
      before(:all) do
        RpXface.setup(ar6)
      end

      context 'passing no params' do
        it 'should enqueue a report with_state_new' do
          expect(RpXface.schedule_report(ar6[:name])).to be_correct(ar6).with_status_new
        end
      end
    end

    context 'for a report with any no of params' do
      ar7 = {name: 'FAILURE_1', params_cnt: 4, param1: {name: 'p1', type: 'date'}, param2: {name: 'p2', type: 'number'},
             param3: {name: 'p2', type: 'number'}, param4: {name: 'p2', type: 'number'}}
             
      before(:all) do
        RpXface.setup(ar7)
      end
      
      context 'for report name which does not exist in rp_available_reports' do
        it 'should fail with_not_found' do
          expect(RpXface.schedule_report('something')).to be_incorrect(ar7).with_not_found
        end
      end
    end

    context 'for a report with 1 text param' do
      ar8 = {name: 'X', params_cnt: 2, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'number'}}
      before(:all) do
        RpXface.setup(ar8)
      end
      
      context 'for not passing params' do
        it 'should fail with_bad_request' do
          expect(RpXface.schedule_report('X')).to be_incorrect(ar8).with_bad_request
        end
      end
      
      context 'for passing params which do not match the report definition' do
        it 'should fail with_bad_request' do
          expect(RpXface.schedule_report('X',
            Date.today,
            'p1'))
          .to be_incorrect(ar8).with_bad_request
        end
      end
    end
  end
end
