require_relative '../spec_helper'

module ThreeScale
  module Backend
    describe ProviderKeyChangeUseCase do
      let(:use_case){ ProviderKeyChangeUseCase.new('foo', 'bar') }

      before do
        Service.save! id: 7001, provider_key: 'foo'
        Service.save! id: 7002, provider_key: 'foo'
        use_case.process
      end

      it 'raises an exception on invalid provider keys' do
        expect { ProviderKeyChangeUseCase.new('foo', 'foo') }.
          to raise_error(InvalidProviderKeys)
      end

      it 'raises an exception if (new) provider key already exists' do
        Service.save! id: 7003, provider_key: 'baz'

        expect { ProviderKeyChangeUseCase.new('bar', 'baz') }.
          to raise_error(ProviderKeyExists)
      end

      it 'raises an exception if (old) key doesn\'t exit' do
        expect { ProviderKeyChangeUseCase.new('baz', 'foo') }.
          to raise_error(ProviderKeyNotFound)
      end

      it 'changes the provider key of existing services' do
        Service.list('bar').should == ['7001', '7002']
        Service.load_by_id(7001).provider_key.should == 'bar'
        Service.load_by_id(7002).provider_key.should == 'bar'
      end

      it 'sets the default service for the new provider key' do
        Service.default_id('bar').should == '7001'
      end

      it 'removes (old) provider key data' do
        Service.default_id('foo').should == nil
        Service.list('foo').should == []
      end
    end
  end
end
