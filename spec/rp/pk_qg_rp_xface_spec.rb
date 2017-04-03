require_relative 'matcher'

class RpAvailableReport
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
            p[s.to_sym] = param.to_s
          end
        end
      end
    plsql.rp_available_reports.insert(args)
  end
  
  def self.schedule_report(name, param1 = nil, param2 = nil, param3 = nil, param4 = nil, param5 = nil, run_at = nil)
    plsql_result = plsql.pk_qg_rp_xface.schedule_report(
    pi_ar_name: name,
    pi_param1: param1,
    pi_param2: param2,
    pi_param3: param3,
    pi_param4: param4,
    pi_param5: param5,
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
  
  def self.get_param_type(param)
    plqsl_result = plsql.pk_qg_rp_xface.get_param_type(pi_param: param)
  end
  
  def self.get_param_name(param)
    plqsl_result = plsql.pk_qg_rp_xface.get_param_name(pi_param: param)
  end
end

describe 'pk_qg_rp_xface' do

  context 'schedule report' do
    ar1 = {name: '5_SUCCESS', params_cnt: 5, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'date'}, 
           param3: {name: 'p3', type: 'number'}, param4: {name: 'p4', type: 'number'}, param5: {name: 'p5', type: 'text'}}
           
    ar2 = {name: '4_SUCCESS', params_cnt: 4, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'date'}, 
           param3: {name: 'p3', type: 'number'}, param4: {name: 'p4', type: 'number'}}
           
    ar3 = {name: '3_SUCCESS', params_cnt: 3, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'date'}, 
          param3: {name: 'p3', type: 'number'}}

    ar4 = {name: '2_SUCCESS', params_cnt: 2, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'date'}}
    
    ar5 = {name: '1_SUCCESS', params_cnt: 1, param1: {name: 'p1', type: 'text'}}
    
    ar6 = {name: '0_SUCCESS', params_cnt: 0}
    
    ar7 = {name: 'FAILURE_1', params_cnt: 4, param1: {name: 'p1', type: 'date'}, param2: {name: 'p2', type: 'number'},
           param3: {name: 'p2', type: 'number'}, param4: {name: 'p2', type: 'number'}}

    ar8 = {name: 'FAILURE_2', params_cnt: 2, param1: {name: 'p1', type: 'date'}, param2: {name: 'p2', type: 'number'}}
  
    before(:all) do
      RpAvailableReport.setup(ar1)
      RpAvailableReport.setup(ar2)
      RpAvailableReport.setup(ar3)
      RpAvailableReport.setup(ar4)
      RpAvailableReport.setup(ar5)
      RpAvailableReport.setup(ar6)
      RpAvailableReport.setup(ar7)
      RpAvailableReport.setup(ar8)
    end
  
    context 'for 5 params' do

      it 'works' do
        expect(RpAvailableReport.schedule_report(ar1[:name], 
          {pri_data_type: 'text', pri_text_value: 'p1', pri_date_value: nil, pri_number_value: nil},
          {pri_data_type: 'date', pri_text_value: nil, pri_date_value: Date.today, pri_number_value: nil},
          {pri_data_type: 'number', pri_text_value: nil, pri_date_value: nil, pri_number_value: 9},
          {pri_data_type: 'number', pri_text_value: nil, pri_date_value: nil, pri_number_value: 8},
          {pri_data_type: 'text', pri_text_value: 'p5', pri_date_value: nil, pri_number_value: nil}))
        .to be_correct(ar1)
      end
    end
    
    context 'for 4 params' do

      it 'works' do
        expect(RpAvailableReport.schedule_report(ar2[:name], 
          {pri_data_type: 'text', pri_text_value: 'p1', pri_date_value: nil, pri_number_value: nil},
          {pri_data_type: 'date', pri_text_value: nil, pri_date_value: Date.today, pri_number_value: nil},
          {pri_data_type: 'number', pri_text_value: nil, pri_date_value: nil, pri_number_value: 9},
          {pri_data_type: 'number', pri_text_value: nil, pri_date_value: nil, pri_number_value: 8}))
        .to be_correct(ar2)
      end
    end
    
    context 'for 3 params' do

      it 'works' do
        expect(RpAvailableReport.schedule_report(ar3[:name], 
          {pri_data_type: 'text', pri_text_value: 'p1', pri_date_value: nil, pri_number_value: nil},
          {pri_data_type: 'date', pri_text_value: nil, pri_date_value: Date.today, pri_number_value: nil},
          {pri_data_type: 'number', pri_text_value: nil, pri_date_value: nil, pri_number_value: 9}))
        .to be_correct(ar3)
      end
    end
    
    context 'for 2 params' do

      it 'works' do
        expect(RpAvailableReport.schedule_report(ar4[:name], 
          {pri_data_type: 'text', pri_text_value: 'p1', pri_date_value: nil, pri_number_value: nil},
          {pri_data_type: 'date', pri_text_value: nil, pri_date_value: Date.today, pri_number_value: nil}))
        .to be_correct(ar4)
      end
    end
    
    context 'for 1 param' do

      it 'works' do
        expect(RpAvailableReport.schedule_report(ar5[:name], 
          {pri_data_type: 'text', pri_text_value: 'p1', pri_date_value: nil, pri_number_value: nil}))
        .to be_correct(ar5)
      end
    end
    
    context 'for 0 param' do

      it 'works' do
        expect(RpAvailableReport.schedule_report(ar6[:name]))
        .to be_correct(ar6)
      end
    end
    
     context 'for invalid report name' do
       it 'gives failure' do
         expect(RpAvailableReport.schedule_report('something')).to be_incorrect(ar7, 'rp:E404')
       end
     end

     context 'for not passing required params' do
       it 'gives failure' do
         expect(RpAvailableReport.schedule_report(ar7[:name])).to be_incorrect(ar7, 'rp:E400')
       end
     end
     
     context 'for invalid params' do
       it 'gives failure' do
         expect(RpAvailableReport.schedule_report(ar8[:name],
           {pri_data_type: 'text', pri_text_value: 'p1', pri_date_value: nil, pri_number_value: nil}))
         .to be_incorrect(ar8, 'rp:E400')
       end
     end
  end
  
  context 'get_param_type' do
    it 'returns date for data type date' do
      expect(RpAvailableReport.get_param_type('{"param1_name":"p1","param1_type":"date"}')).to eq('date')
    end
    
    it 'returns number for data type number' do
      expect(RpAvailableReport.get_param_type('{"param2_name":"p2","param2_type":"number"}')).to eq('number')
    end
    
    it 'returns text for data type text' do
      expect(RpAvailableReport.get_param_type('{"param3_name":"p3","param3_type":"text"}')).to eq('text')
    end
    
    it 'returns nil for any other data type' do
      expect(RpAvailableReport.get_param_type('{"param3_name":"p3","param3_type":"boolean"}')).to eq(nil)
    end
  end
  
  context 'get_param_name' do
    it 'returns name of the param' do
      expect(RpAvailableReport.get_param_name('{"param1_name":"p1","param1_type":"date"}')).to eq('p1')
    end
  end
end
