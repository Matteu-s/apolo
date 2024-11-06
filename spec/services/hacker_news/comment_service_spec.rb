require 'rails_helper'

RSpec.describe HackerNews::CommentService do
  let(:service) { described_class.new }

  describe '#fetch_comments' do
    let(:comment_response) do
      {
        'id' => 789,
        'text' => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
        'kids' => [101, 102]
      }
    end

    let(:reply_response) do
      {
        'id' => 101,
        'text' => 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
      }
    end

    let(:reply_response_2) do
      {
        'id' => 102,
        'text' => 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt.'
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
      expect(result.first['text']).to eq('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.')
      expect(result.first['replies']).to be_present
      expect(result.first['replies'].size).to eq(2)
      expect(result.first['replies'].map do |r|
        r['text']
      end).to match_array([
                            'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt.'
                          ])
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
