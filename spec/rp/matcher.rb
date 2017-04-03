require 'rspec/expectations'

RSpec::Matchers.define :be_correct do |ar|
  match do |r|
    expect(r[:name]).to eq(ar[:name])
    expect(r[:state]).to eq('NEW')
    expect(r[:param1]).to be_nil if ar[:params_cnt] < 1
    
    if ar[:params_cnt] == 1
      expect(r[:param1]).to_not be_nil
      expect(r[:param2]).to be_nil
      expect(r[:param3]).to be_nil
      expect(r[:param4]).to be_nil
      expect(r[:param5]).to be_nil
    end

    if ar[:params_cnt] == 2
      expect(r[:param1]).to_not be_nil
      expect(r[:param2]).to_not be_nil
      expect(r[:param3]).to be_nil
      expect(r[:param4]).to be_nil
      expect(r[:param5]).to be_nil
    end

    if ar[:params_cnt] == 3
      expect(r[:param1]).to_not be_nil
      expect(r[:param2]).to_not be_nil
      expect(r[:param3]).to_not be_nil
      expect(r[:param4]).to be_nil
      expect(r[:param5]).to be_nil
    end

    if ar[:params_cnt] == 4
      expect(r[:param1]).to_not be_nil
      expect(r[:param2]).to_not be_nil
      expect(r[:param3]).to_not be_nil
      expect(r[:param4]).to_not be_nil
      expect(r[:param5]).to be_nil
    end

    if ar[:params_cnt] == 5
      expect(r[:param1]).to_not be_nil
      expect(r[:param2]).to_not be_nil
      expect(r[:param3]).to_not be_nil
      expect(r[:param4]).to_not be_nil
      expect(r[:param5]).to_not be_nil
    end
    
    expect(r[:fault_code]).to be_nil
    expect(r[:fault_reason]).to be_nil    
  end
  
  failure_message do |r|
    "rp_report not as expected : #{r}"
  end  
end

RSpec::Matchers.define :be_incorrect do |ar, code|
  match do |r|
    expect(r[:fault_code]).to_not be_nil
    expect(r[:fault_reason]).to_not be_nil
    
    expect(r[:fault_code]).to eq(code)   
  end
  
  failure_message do |r|
    "rp_report not as expected : #{r}"
  end  
end