# Usando imagem base do Ruby 3.3.5
FROM ruby:3.3.5

# Instalando dependências básicas
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# Instalando o Bun
RUN curl -fsSL https://bun.sh/install | bash

# Definindo variáveis de ambiente para o Bun
ENV PATH="/root/.bun/bin:${PATH}"

# Criando diretório de trabalho
WORKDIR /app

# Copiando arquivos do projeto
COPY . /app

# Instalando dependências do sistema
RUN bundle install

# Expondo a porta
EXPOSE 3000

# Comando para iniciar o servidor
CMD ["rails", "server", "-b", "0.0.0.0"]
