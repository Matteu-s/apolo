require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  let(:story_service) { instance_double(HackerNews::StoryService) }
  let(:comment_service) { instance_double(HackerNews::CommentService) }

  before do
    allow(HackerNews::StoryService).to receive(:new).and_return(story_service)
    allow(HackerNews::CommentService).to receive(:new).and_return(comment_service)
  end

  describe 'GET #index' do
    let(:stories) do
      [
        { 'id' => 1, 'title' => 'Story 1', 'time' => Time.now.to_i },
        { 'id' => 2, 'title' => 'Story 2', 'time' => Time.now.to_i - 100 }
      ].sort_by { |story| -story['time'].to_i }
    end

    context 'sem parâmetro de busca' do
      before do
        allow(story_service).to receive(:fetch_top_stories).and_return([1, 2])
        allow(story_service).to receive(:fetch_story_details).and_return(stories)
        allow(Rails.cache).to receive(:fetch).with('top_stories', expires_in: 5.minutes).and_yield
      end

      it 'retorna as top stories' do
        get :index
        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get('@stories')).to eq(stories)
      end

      it 'usa cache para armazenar as histórias' do
        expect(Rails.cache).to receive(:fetch).with('top_stories', expires_in: 5.minutes)
        get :index
      end
    end

    context 'com parâmetro de busca' do
      let(:query) { 'ruby' }
      let(:search_results) do
        [{ 'id' => 1, 'title' => 'Ruby Story', 'time' => Time.now.to_i }]
      end

      before do
        allow(story_service).to receive(:search_stories).with(query).and_return(search_results)
        allow(Rails.cache).to receive(:fetch).with("search_stories_#{query}", expires_in: 1.minute).and_yield
      end

      it 'retorna resultados da busca' do
        get :index, params: { q: query }
        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get('@stories')).to eq(search_results)
      end

      it 'usa cache para armazenar os resultados da busca' do
        expect(Rails.cache).to receive(:fetch).with("search_stories_#{query}", expires_in: 1.minute)
        get :index, params: { q: query }
      end
    end
  end

  describe 'GET #comments' do
    let(:story_id) { '1' }
    let(:story) do
      {
        'id' => story_id,
        'title' => 'Test Story',
        'kids' => [10, 11, 12]
      }
    end

    let(:comments) do
      [
        { 'id' => 10, 'text' => 'Comment 1' },
        { 'id' => 11, 'text' => 'Comment 2' }
      ]
    end

    before do
      allow(story_service).to receive(:fetch_story_details).with(story_id).and_return(story)
      allow(comment_service).to receive(:fetch_comments).with(story['kids']).and_return(comments)
      allow(Rails.cache).to receive(:fetch).with("comments_#{story_id}", expires_in: 5.minutes).and_yield
    end

    it 'carrega a história e seus comentários' do
      get :comments, params: { id: story_id }

      expect(response).to have_http_status(:success)
      expect(controller.instance_variable_get('@story')).to eq(story)
      expect(controller.instance_variable_get('@comments')).to eq(comments)
    end

    it 'usa cache para armazenar os comentários' do
      expect(Rails.cache).to receive(:fetch).with("comments_#{story_id}", expires_in: 5.minutes)
      get :comments, params: { id: story_id }
    end

    context 'quando a história não tem comentários' do
      let(:story_without_comments) do
        {
          'id' => '2',
          'title' => 'Story without comments'
        }
      end

      before do
        allow(story_service).to receive(:fetch_story_details)
          .with('2')
          .and_return(story_without_comments)

        allow(Rails.cache).to receive(:fetch)
          .with('comments_2', expires_in: 5.minutes)
          .and_yield
      end

      it 'retorna a história sem comentários' do
        get :comments, params: { id: '2' }

        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get('@story')).to eq(story_without_comments)
        expect(controller.instance_variable_get('@comments')).to be_nil
      end
    end
  end
end
