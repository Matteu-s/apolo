require 'rails_helper'

RSpec.describe HackerNews::StoryService do
  let(:service) { described_class.new }

  describe '#fetch_story_details' do
    let(:story_response) do
      {
        'id' => 123,
        'title' => 'Test Story',
        'text' => 'Test content',
        'time' => Time.now.to_i
      }
    end

    before do
      allow(service).to receive(:make_request).and_return(story_response)
    end

    context 'quando recebe um único ID' do
      it 'retorna os detalhes de uma história' do
        result = service.fetch_story_details(123)
        expect(result).to eq(story_response)
      end
    end

    context 'quando recebe múltiplos IDs' do
      it 'retorna um array com os detalhes das histórias' do
        result = service.fetch_story_details([123, 456])
        expect(result).to eq([story_response, story_response])
      end
    end

    context 'quando o ID é nil' do
      it 'retorna um array vazio' do
        expect(service.fetch_story_details(nil)).to eq([])
      end
    end
  end

  describe '#search_stories' do
    let(:story_ids) { [123, 456] }
    let(:stories) do
      [
        { 'id' => 123, 'title' => 'Ruby Test', 'time' => Time.now.to_i },
        { 'id' => 456, 'title' => 'Other Story', 'time' => Time.now.to_i - 100 }
      ]
    end

    before do
      allow(service).to receive(:fetch_new_story_ids).and_return(story_ids)
      allow(service).to receive(:fetch_story_details).and_return(stories)
    end

    it 'retorna histórias que correspondem à consulta' do
      result = service.search_stories('ruby')
      expect(result.size).to eq(1)
      expect(result.first['title']).to include('Ruby')
    end

    it 'retorna array vazio para consulta em branco' do
      expect(service.search_stories('')).to eq([])
    end
  end
end
