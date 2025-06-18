FROM ruby:3.4.4

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libvips-dev \
    imagemagick \
    libmagickwand-dev \
    libmagic-dev \
    libsqlite3-dev \
    curl \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Instalar Node.js 23
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get install -y nodejs

# Instalar pnpm 10.x
RUN npm install -g pnpm@10.2.0

# Configurar diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependências
COPY Gemfile Gemfile.lock ./
COPY package.json pnpm-lock.yaml ./

# Instalar dependências Ruby
RUN bundle install

# Instalar dependências JavaScript
RUN pnpm install --frozen-lockfile

# Copiar código da aplicação
COPY . .

# Compilar assets
ENV RAILS_ENV=production
ENV RAILS_GROUPS=assets
RUN bundle exec rake assets:precompile

# Expor porta
EXPOSE 3000

# Comando padrão
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"] 