# Usando imagem base do Ruby 3.3.5
FROM ruby:3.3.5

# Instalando dependências básicas
RUN apt-get update -qq && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Criando diretório de trabalho
WORKDIR /app

# Copiando Gemfile primeiro para aproveitar o cache do Docker
COPY Gemfile Gemfile.lock ./

# Instalando dependências do Ruby
RUN bundle install

# Copiando o resto dos arquivos do projeto
COPY . /app

# Expondo a porta
EXPOSE 3000

# Comando para iniciar o servidor
CMD ["rails", "server", "-b", "0.0.0.0"]
