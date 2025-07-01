# ref: https://github.com/rails/rails/issues/43906#issuecomment-1094380699
# https://github.com/rails/rails/issues/43906#issuecomment-1099992310
task before_assets_precompile: :environment do
  # Garantir que pnpm esteja disponível no PATH
  original_path = ENV['PATH']
  ENV['PATH'] = "/usr/local/bin:/usr/local/lib/node_modules/.bin:#{original_path}"
  
  puts "=== Debugging Node.js and pnpm availability ==="
  puts "PATH: #{ENV['PATH']}"
  puts "Node.js version: #{`node --version 2>/dev/null`.strip}"
  puts "Node.js location: #{`which node 2>/dev/null`.strip}"
  puts "npm version: #{`npm --version 2>/dev/null`.strip}"
  puts "pnpm location: #{`which pnpm 2>/dev/null`.strip}"
  puts "pnpm version: #{`pnpm --version 2>/dev/null`.strip}"
  puts "Current user: #{`whoami`.strip}"
  puts "All Node.js installations:"
  system("find /usr -name 'node' -type f 2>/dev/null | head -10")
  puts "=============================================="
  
  # Verificar se o Node.js é da versão correta (23.x conforme package.json)
  node_version = `node --version 2>/dev/null`.strip.gsub('v', '')
  node_major = node_version.split('.').first.to_i if !node_version.empty?
  
  puts "Node.js detectado: versão #{node_version}, major: #{node_major}"
  
  # Se Node.js não é 23.x, instalar a versão correta
  if node_major != 23
    puts "⚠️  Node.js #{node_version} não é compatível com package.json (requer 23.x)"
    puts "Instalando Node.js 23.x..."
    
    if system("curl -fsSL https://deb.nodesource.com/setup_23.x | sudo -E bash - && sudo apt-get install -y nodejs")
      puts "✅ Node.js 23.x instalado"
      
      # Forçar uso do Node.js recém-instalado
      ENV['PATH'] = "/usr/bin:/usr/local/bin:/usr/local/lib/node_modules/.bin:#{original_path}"
      
      # Verificar todas as instalações do Node.js e usar a correta
      puts "Verificando instalações do Node.js:"
      system("find /usr -name 'node' -type f 2>/dev/null | head -10")
      
      # Tentar usar o Node.js correto diretamente
      node_23_path = "/usr/bin/node"
      if File.exist?(node_23_path)
        puts "Usando Node.js em #{node_23_path}"
        node_version = `#{node_23_path} --version 2>/dev/null`.strip.gsub('v', '')
        node_major = node_version.split('.').first.to_i
        puts "Nova versão do Node.js: #{node_version}"
        
        # Atualizar PATH para usar esta versão
        ENV['PATH'] = "/usr/bin:/usr/local/bin:#{original_path}"
      else
        abort("❌ Não foi possível encontrar o Node.js 23.x instalado em #{node_23_path}")
      end
    else
      abort("❌ Falha ao instalar Node.js 23.x")
    end
  end
  
  # Verificar se pnpm está disponível e na versão correta (10.x conforme package.json)
  pnpm_version = `pnpm --version 2>/dev/null`.strip
  pnpm_major = pnpm_version.split('.').first.to_i if !pnpm_version.empty?
  
  if !system('which pnpm > /dev/null 2>&1') || pnpm_major != 10
    puts "⚠️  pnpm não encontrado ou versão incorreta (#{pnpm_version}, requer 10.x)"
    puts "Instalando pnpm 10.x para Node.js #{node_major}..."
    
    # Usar o Node.js correto para instalar pnpm com sudo
    node_path = `which node`.strip
    npm_path = `which npm`.strip
    
    puts "Usando Node.js: #{node_path}"
    puts "Usando npm: #{npm_path}"
    
    if system("sudo #{npm_path} install -g pnpm@10.2.0")
      puts "✅ pnpm 10.x instalado, criando symlinks..."
      
      # Tentar diferentes localizações para o pnpm
      pnpm_locations = [
        "/usr/lib/node_modules/pnpm/bin/pnpm.cjs",
        "/usr/lib/node_modules/pnpm/bin/pnpm.js",
        "/usr/local/lib/node_modules/pnpm/bin/pnpm.cjs",
        "/usr/local/lib/node_modules/pnpm/bin/pnpm.js"
      ]
      
      pnpm_source = pnpm_locations.find { |path| File.exist?(path) }
      
      if pnpm_source
        puts "Encontrado pnpm em: #{pnpm_source}"
        system("sudo ln -sf #{pnpm_source} /usr/bin/pnpm")
        system("sudo ln -sf #{pnpm_source.gsub('pnpm', 'pnpx')} /usr/bin/pnpx") if File.exist?(pnpm_source.gsub('pnpm', 'pnpx'))
      else
        puts "Procurando pnpm automaticamente..."
        system("find /usr -name 'pnpm*' -type f 2>/dev/null | head -5")
        
        # Tentar criar symlink para o pnpm usando npm root
        npm_global_dir = `#{npm_path} root -g 2>/dev/null`.strip
        potential_pnpm = "#{npm_global_dir}/pnpm/bin/pnpm.cjs"
        if File.exist?(potential_pnpm)
          puts "Encontrado pnpm em npm global: #{potential_pnpm}"
          system("sudo ln -sf #{potential_pnpm} /usr/bin/pnpm")
        end
      end
      
      # Atualizar PATH e verificar
      ENV['PATH'] = "/usr/bin:/usr/local/bin:/usr/local/lib/node_modules/.bin:#{original_path}"
      
      puts "Verificando pnpm após instalação:"
      puts "which pnpm: #{`which pnpm 2>/dev/null`.strip}"
      puts "pnpm version: #{`pnpm --version 2>/dev/null`.strip}"
    else
      abort("❌ Falha ao instalar pnpm 10.x")
    end
  end
  
  # Verificação final das versões
  final_node_version = `node --version 2>/dev/null`.strip
  final_pnpm_version = `pnpm --version 2>/dev/null`.strip
  
  puts "=== Verificação final antes dos comandos ==="
  puts "Node.js: #{final_node_version}"
  puts "pnpm: #{final_pnpm_version}"
  puts "pnpm location: #{`which pnpm 2>/dev/null`.strip}"
  puts "Node.js location: #{`which node 2>/dev/null`.strip}"
  puts "=============================================="
  
  # Verificar se as versões estão corretas agora
  if final_node_version.start_with?('v23.') && !final_pnpm_version.empty?
    puts "✅ Versões corretas detectadas, executando comandos..."
    
    # Configurar ambiente para ViteRuby usar as versões corretas
    puts "=== Configurando ambiente para ViteRuby ==="
    
    # Criar um wrapper para o pnpm que garante uso do Node.js correto
    wrapper_content = <<~SCRIPT
      #!/bin/bash
      export PATH="/usr/bin:/usr/local/bin:$PATH"
      exec /usr/bin/pnpm "$@"
    SCRIPT
    
    # Escrever wrapper temporário
    File.write('/tmp/pnpm-wrapper', wrapper_content)
    system('sudo chmod +x /tmp/pnpm-wrapper')
    system('sudo cp /tmp/pnpm-wrapper /usr/local/bin/pnpm-wrapper')
    
    # Definir variáveis de ambiente para o sistema
    ENV['NODE_PATH'] = '/usr/bin/node'
    ENV['PNPM_PATH'] = '/usr/bin/pnpm'
    
    # Executar comandos pnpm
    system('pnpm install') || abort("❌ Falha ao executar pnpm install")
    system('echo "-------------- Bulding SDK for Production --------------"')
    system('pnpm run build:sdk') || abort("❌ Falha ao executar pnpm run build:sdk")
    system('echo "-------------- Bulding App for Production --------------"')
    
    # **NÃO** restaurar PATH original para manter Node.js 23.x disponível para ViteRuby
    puts "=== Mantendo Node.js 23.x e pnpm 10.x disponíveis para ViteRuby ==="
    puts "PATH final: #{ENV['PATH']}"
    puts "Node.js final: #{`node --version 2>/dev/null`.strip}"
    puts "pnpm final: #{`pnpm --version 2>/dev/null`.strip}"
    puts "NODE_PATH: #{ENV['NODE_PATH']}"
    puts "PNPM_PATH: #{ENV['PNPM_PATH']}"
  else
    abort("❌ Versões ainda incorretas após instalação. Node.js: #{final_node_version}, pnpm: #{final_pnpm_version}")
  end
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task['assets:precompile'].enhance %w[before_assets_precompile]
