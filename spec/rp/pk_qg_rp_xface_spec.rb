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
      puts args
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
end

describe 'pk_qg_rp_xface' do

  context 'for 5 params' do
    ar1 = {name: '5 params', params_cnt: 2, param1: {name: 'p1', type: 'text'}, param2: {name: 'p2', type: 'date'}}
    ar2 = {name: '5 params failure', params_cnt: 2, param1: {name: 'p1', type: 'date'}, param2: {name: 'p2', type: 'number'}}
    
    before(:all) do
      RpAvailableReport.setup(ar1)
      RpAvailableReport.setup(ar2)
    end
    
    context 'schedule_report' do

      it 'works' do
        expect(RpAvailableReport.schedule_report(ar1[:name], 
          {pri_data_type: 'text', pri_text_value: 'p1', pri_date_value: nil, pri_number_value: nil},
          {pri_data_type: 'date', pri_text_value: nil, pri_date_value: Date.today, pri_number_value: nil}))
        .to be_correct(ar1)
      end

      it 'gives error when params are not passed' do
        expect(RpAvailableReport.schedule_report(ar2[:name])).to be_incorrect(ar2)
      end
    end
  end
end
