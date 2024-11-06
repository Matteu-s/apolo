require 'rails_helper'

RSpec.describe HackerNews::CommentService do
  let(:service) { described_class.new }

  describe '#fetch_comments' do
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
      allow(service).to receive(:make_request)
        .with("#{service.send(:api_url)}/item/789.json")
        .and_return(comment_response)

      allow(service).to receive(:make_request)
        .with("#{service.send(:api_url)}/item/101.json")
        .and_return(reply_response)

      allow(service).to receive(:make_request)
        .with("#{service.send(:api_url)}/item/102.json")
        .and_return(reply_response_2)
    end

    it 'retorna comentários com respostas' do
      result = service.fetch_comments([789])
      expect(result.first['text']).to eq('Test comment')
      expect(result.first['replies']).to be_present
      expect(result.first['replies'].size).to eq(2)
      expect(result.first['replies'].map { |r| r['text'] }).to match_array(['Test reply', 'Test reply 2'])
    end

    context 'quando excede a profundidade máxima' do
      it 'retorna array vazio' do
        expect(service.fetch_comments([789], 3)).to eq([])
      end
    end

    context 'quando os IDs estão em branco' do
      it 'retorna array vazio' do
        expect(service.fetch_comments([])).to eq([])
      end
    end
  end
end
