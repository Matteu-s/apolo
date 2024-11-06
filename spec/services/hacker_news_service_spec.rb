require 'rails_helper'

RSpec.describe HackerNewsService do
  describe '.fetch_story_details' do
    let(:story_response) do
      {
        'id' => 123,
        'title' => 'Test Story',
        'text' => 'Test content',
        'time' => Time.now.to_i
      }
    end

    before do
      allow(HackerNewsService).to receive(:make_request).and_return(story_response)
    end

    context 'quando recebe um único ID' do
      it 'retorna os detalhes de uma história' do
        result = described_class.fetch_story_details(123)
        expect(result).to eq(story_response)
      end
    end

    context 'quando recebe múltiplos IDs' do
      it 'retorna um array com os detalhes das histórias' do
        result = described_class.fetch_story_details([123, 456])
        expect(result).to eq([story_response, story_response])
      end
    end

    context 'quando o ID é nil' do
      it 'retorna um array vazio' do
        expect(described_class.fetch_story_details(nil)).to eq([])
      end
    end
  end

  describe '.fetch_comments' do
    let(:comment_response) do
      {
        'id' => 789,
        'text' => 'Test comment',
        'kids' => [101, 102]
      }
    end

    let(:reply_response) do
      {
        'id' => 101,
        'text' => 'Test reply'
      }
    end

    let(:reply_response_2) do
      {
        'id' => 102,
        'text' => 'Test reply 2'
      }
    end

    before do
      allow(HackerNewsService).to receive(:make_request)
        .with("#{described_class::HACKER_NEWS_API}/item/789.json")
        .and_return(comment_response)

      allow(HackerNewsService).to receive(:make_request)
        .with("#{described_class::HACKER_NEWS_API}/item/101.json")
        .and_return(reply_response)

      allow(HackerNewsService).to receive(:make_request)
        .with("#{described_class::HACKER_NEWS_API}/item/102.json")
        .and_return(reply_response_2)
    end

    it 'retorna comentários com respostas' do
      result = described_class.fetch_comments([789])
      expect(result.first['text']).to eq('Test comment')
      expect(result.first['replies']).to be_present
      expect(result.first['replies'].size).to eq(2)
      expect(result.first['replies'].map { |r| r['text'] }).to match_array(['Test reply', 'Test reply 2'])
    end
  end

  describe '.search_stories' do
    let(:story_ids) { [123, 456] }
    let(:stories) do
      [
        { 'id' => 123, 'title' => 'Ruby Test', 'time' => Time.now.to_i },
        { 'id' => 456, 'title' => 'Other Story', 'time' => Time.now.to_i - 100 }
      ]
    end

    before do
      allow(described_class).to receive(:fetch_new_story_ids).and_return(story_ids)
      allow(described_class).to receive(:fetch_story_details).and_return(stories)
    end

    it 'retorna histórias que correspondem à consulta' do
      result = described_class.search_stories('ruby')
      expect(result.size).to eq(1)
      expect(result.first['title']).to include('Ruby')
    end

    it 'retorna array vazio para consulta em branco' do
      expect(described_class.search_stories('')).to eq([])
    end
  end

  describe '.make_request' do
    let(:url) { "#{described_class::HACKER_NEWS_API}/item/123.json" }
    let(:response) { instance_double(Net::HTTPSuccess, body: '{"id": 123}') }

    before do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    end

    it 'faz uma requisição HTTP e retorna o JSON parseado' do
      result = described_class.make_request(url)
      expect(result).to eq({ 'id' => 123 })
    end

    context 'quando ocorre um erro' do
      before do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(StandardError.new('Erro de conexão'))
      end

      it 'registra o erro e retorna nil' do
        expect(Rails.logger).to receive(:error).with(/Erro na requisição/)
        expect(described_class.make_request(url)).to be_nil
      end
    end
  end
end
