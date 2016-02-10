require 'spec_helper'
describe 'cfnetwork' do

  context 'with defaults for all parameters' do
    it { should contain_class('cfnetwork') }
  end
end
