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
      
      args[:params_cnt] ||= 0 # defaut params_cnt = 0
      
      args = args.tap do |p|
        (1..args[:params_cnt]).each do |i|
          s = "param#{i}"
          s_name = "#{s}_name".to_sym
          s_type = "#{s}_type".to_sym
          if p[s.to_sym].instance_of?(Hash)
            param = {}
            param[s_name] = p[s.to_sym][:name]
            param[s_type] = p[s.to_sym][:type]
            p[s.to_sym] = JSON.generate(param)
          else
            # default param, when the case does not care about the param
            param = {}
            param[s_name] = "p#{i}"
            param[s_type] = "text"
            p[s.to_sym] = JSON.generate(param)
          end
        end
      end  
    plsql.rp_available_reports.insert(args)
  end
  
  def self.get_param(params, i)
    return nil if params.nil?
    return nil if params.length < i 
    return {pri_data_type: 'text', pri_text_value: params[i], pri_date_value: nil, pri_number_value: nil} if params[i].is_a?(String)
    return {pri_data_type: 'date', pri_text_value: nil, pri_date_value: params[i], pri_number_value: nil} if params[i].is_a?(Date)
    return {pri_data_type: 'number', pri_text_value: nil, pri_date_value: nil, pri_number_value: params[i]} if params[i].is_a?(Integer)
  end
  
  def self.schedule_report(name, params = nil, run_at = nil)

    plsql_result = plsql.pk_qg_rp_xface.schedule_report(
    pi_ar_name: name,
    pi_param1: get_param(params, 0),
    pi_param2: get_param(params, 1),
    pi_param3: get_param(params, 2),
    pi_param4: get_param(params, 3),
    pi_param5: get_param(params, 4),
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


def make_param_scenarios(params_cnt)
  opts = ['text', 'date', 'number']
  cases = Array.new  
  (1..3).each do |a|
    (1..3).each do |b|
      (1..3).each do |c|
        (1..3).each do |d|
          (1..3).each do |e|
            params = Array.new(params_cnt)
            params[0] = opts[a % 3] if params_cnt > 0
            params[1] = opts[b % 3] if params_cnt > 1
            params[2] = opts[c % 3] if params_cnt > 2
            params[3] = opts[d % 3] if params_cnt > 3
            params[4] = opts[e % 3] if params_cnt > 4
            cases << params
          end
        end
      end
    end
  end
  cases.uniq
end

def make_params(scenario)
  # param1: {name: 'p1', type: 'text'}
  params = {}
  scenario.each_with_index do |s, i|
    params["param#{i+1}".to_sym] = {name: "p#{i+1}", type: s}
  end
  params
end

def make_param_values(scenario, happy = true)
  values = []
  scenario.each do |s|
    values << Date.today if s == 'date'
    values << 'x' if s == 'text'
    values << 1 if s == 'number'
  end
  
  unless happy
    # the last parameters value is set to be different than the data-type
    values[-1] = 1 if values[-1].is_a?(Date)
    values[-1] = Date.today if values[-1].is_a?(String)
    values[-1] = 'y' if values[-1].is_a?(Integer)
    
  end
  
  values  
end

describe 'pk_qg_rp_xface' do
  
  # scenarios for exactly the required no of parameters are passed
  (0..5).each do |params_cnt|
    context "for a report with #{params_cnt} params" do
      ar = {name: "ar_p_#{params_cnt}", params_cnt: params_cnt}

      before(:all) do
        RpXface.setup(ar)
      end

      (0..5).each do |i|
        context "and scheduling a report by passing #{i} params" do
          if i == params_cnt
            it 'should enqueue a report with_state_new' do
              expect(RpXface.schedule_report(ar[:name], Array.new(i, 'x'))).to be_correct(ar).with_status_new
            end
          else
            it 'should enqueue fail with_bad_request' do
              expect(RpXface.schedule_report(ar[:name], Array.new(i, 'x'))).to be_incorrect(ar).with_bad_request
            end
          end
        end
      end
    end
  end


  # scenarios to check that the parameter passed is as per definition
  (1..5).each do |params_cnt|
    context "for a report with #{params_cnt} params" do
      scenarios = make_param_scenarios(params_cnt)
      scenarios.each_with_index do |scenario, x|
        context "and param definition as #{scenario}" do
          ar = {name: "ar_pd_#{params_cnt}_#{x}", params_cnt: params_cnt}.merge(make_params(scenario))

          before(:all) do
            RpXface.setup(ar)
          end
          
          scenario.each_with_index do |s,i|
            # failure cases
            context "and param #{i+1} values as #{make_param_values(scenario, false)}" do
              it "should fail with_bad_input" do
                expect(RpXface.schedule_report(ar[:name], make_param_values(scenario, false))).to be_incorrect(ar).with_bad_request
              end
            end
          end
          
          # all params passed with correct types
          context "and param values as #{make_param_values(scenario)}" do
            it "should schedule with_status_new" do
              expect(RpXface.schedule_report(ar[:name], make_param_values(scenario))).to be_correct(ar).with_status_new
            end
          end
          
        end
      end
    end    
  end
  
    context 'for a report with any no of params' do
      ar1 = {name: 'FAILURE_1', params_cnt: 4, param1: {name: 'p1', type: 'date'}, param2: {name: 'p2', type: 'number'},
             param3: {name: 'p2', type: 'number'}, param4: {name: 'p2', type: 'number'}}
             
      ar2 = {name: 'FAILURE_1', params_cnt: 1, param1: {name: 'p1', type: 'date'}}

      before(:all) do
        RpXface.setup(ar1)
        RpXface.setup(ar2)
      end

      context 'for report name which does not exist in rp_available_reports' do
        it 'should fail with_not_found' do
          expect(RpXface.schedule_report('something')).to be_incorrect(ar1).with_not_found
        end
      end
      
      context 'for report name which has more than one row in rp_available_reports' do
        it 'should fail with_bad_setup' do
          expect(RpXface.schedule_report('FAILURE_1')).to be_incorrect(ar2).with_bad_setup
        end
      end
    end
end
