require_relative 'matcher'
require 'json'

class RpXfaceHelper
  def self.to_json(param)
    JSON.generate(param)
  end

  def self.get_param_type(param)
    plqsl_result = plsql.pk_qg_rp_xface_helper.get_param_type(pi_param: to_json(param))
  end

  def self.get_param_name(param)
    plqsl_result = plsql.pk_qg_rp_xface_helper.get_param_name(pi_param: to_json(param))
  end
end

describe 'pk_qg_rp_xface_helper' do
  context 'get_param_type' do
    it 'should return date for data type date' do
      expect(RpXfaceHelper.get_param_type({param1_name: 'p1', param1_type: 'date'})).to eq('date')
    end

    it 'should return number for data type number' do
      expect(RpXfaceHelper.get_param_type({param1_name: 'p2', param1_type: 'number'})).to eq('number')
    end

    it 'should return text for data type text' do
      expect(RpXfaceHelper.get_param_type({param1_name: 'p3', param1_type: 'text'})).to eq('text')
    end

    it 'should return nil for any other data type' do
      expect(RpXfaceHelper.get_param_type({param1_name: 'p4', param1_type: 'boolean'})).to eq(nil)
    end
  end

  context 'get_param_name' do
    it 'should return the name of the param' do
      expect(RpXfaceHelper.get_param_name({param1_name: 'p1', param1_type: 'date'})).to eq('p1')
    end
  end
end