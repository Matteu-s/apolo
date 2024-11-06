require 'rails_helper'

RSpec.describe HackerNews::BaseClient do
  let(:client) { Class.new(described_class).new }
  let(:url) { 'https://hacker-news.firebaseio.com/v0/item/123.json' }
  let(:response) { instance_double(Net::HTTPSuccess, body: '{"id": 123}') }

  describe '#make_request' do
    before do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    end

    it 'faz uma requisição HTTP e retorna o JSON parseado' do
      result = client.send(:make_request, url)
      expect(result).to eq({ 'id' => 123 })
    end

    context 'quando ocorre um erro' do
      before do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(StandardError.new('Erro de conexão'))
      end

      it 'registra o erro e retorna nil' do
        expect(Rails.logger).to receive(:error).with(/Erro na requisição/)
        expect(client.send(:make_request, url)).to be_nil
      end
    end
  end
end
