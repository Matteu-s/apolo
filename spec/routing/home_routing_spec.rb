require 'rails_helper'

RSpec.describe 'Rotas para Home', type: :routing do
  it 'roteia / para home#index' do
    expect(get: '/').to route_to(
      controller: 'home',
      action: 'index'
    )
  end

  it 'roteia /story/:id/comments para home#comments' do
    expect(get: '/story/123/comments').to route_to(
      controller: 'home',
      action: 'comments',
      id: '123'
    )
  end

  it 'gera a rota root_path corretamente' do
    expect(root_path).to eq('/')
  end

  it 'gera a rota story_comments_path corretamente' do
    expect(story_comments_path(123)).to eq('/story/123/comments')
  end

  it 'não roteia caminhos inválidos para comments' do
    expect(get: '/story/comments').not_to be_routable
    expect(get: '/story//comments').not_to be_routable
  end
end
