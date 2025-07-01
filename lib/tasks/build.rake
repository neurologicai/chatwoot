# ref: https://github.com/rails/rails/issues/43906#issuecomment-1094380699
# https://github.com/rails/rails/issues/43906#issuecomment-1099992310
task before_assets_precompile: :environment do
  # Garantir que pnpm esteja disponível no PATH
  original_path = ENV['PATH']
  ENV['PATH'] = "/usr/local/bin:/usr/local/lib/node_modules/.bin:#{original_path}"
  
  puts "=== Debugging Node.js and pnpm availability ==="
  puts "PATH: #{ENV['PATH']}"
  puts "Node.js version: #{`node --version 2>/dev/null`.strip}"
  puts "npm version: #{`npm --version 2>/dev/null`.strip}"
  puts "pnpm location: #{`which pnpm 2>/dev/null`.strip}"
  puts "pnpm version: #{`pnpm --version 2>/dev/null`.strip}"
  puts "Current user: #{`whoami`.strip}"
  puts "=============================================="
  
  # Verificar se pnpm está disponível antes de usar
  if system('which pnpm > /dev/null 2>&1')
    puts "✅ pnpm encontrado, executando comandos..."
    # run a command which starts your packaging
    system('pnpm install') || abort("❌ Falha ao executar pnpm install")
    system('echo "-------------- Bulding SDK for Production --------------"')
    system('pnpm run build:sdk') || abort("❌ Falha ao executar pnpm run build:sdk")
    system('echo "-------------- Bulding App for Production --------------"')
  else
    puts "❌ pnpm não encontrado no PATH"
    puts "Tentando instalar pnpm globalmente..."
    
    # Verificar versão do Node.js e escolher versão compatível do pnpm
    node_version = `node --version 2>/dev/null`.strip.gsub('v', '')
    puts "Node.js detectado: #{node_version}"
    
    if node_version.empty?
      abort("❌ Node.js não encontrado")
    end
    
    # Para Node.js 16, usar pnpm 8.x que é compatível
    major_version = node_version.split('.').first.to_i
    pnpm_version = major_version >= 18 ? "10.2.0" : "8.15.1"
    
    puts "Usando pnpm versão #{pnpm_version} (compatível com Node.js #{major_version})"
    
    if system("sudo npm install -g pnpm@#{pnpm_version}")
      puts "✅ pnpm instalado, criando symlinks..."
      system("sudo ln -sf /usr/local/lib/node_modules/pnpm/bin/pnpm.cjs /usr/local/bin/pnpm 2>/dev/null || true")
      system("sudo ln -sf /usr/local/lib/node_modules/pnpm/bin/pnpx.cjs /usr/local/bin/pnpx 2>/dev/null || true")
      
      # Atualizar PATH e tentar novamente
      ENV['PATH'] = "/usr/local/bin:/usr/local/lib/node_modules/.bin:#{original_path}"
      
      puts "Verificando pnpm após instalação:"
      puts "which pnpm: #{`which pnpm 2>/dev/null`.strip}"
      puts "pnpm version: #{`pnpm --version 2>/dev/null`.strip}"
      
      if system('which pnpm > /dev/null 2>&1')
        puts "✅ pnpm agora disponível, executando comandos..."
        system('pnpm install') || abort("❌ Falha ao executar pnpm install")
        system('echo "-------------- Bulding SDK for Production --------------"')
        system('pnpm run build:sdk') || abort("❌ Falha ao executar pnpm run build:sdk")
        system('echo "-------------- Bulding App for Production --------------"')
      else
        abort("❌ pnpm ainda não está disponível após instalação")
      end
    else
      abort("❌ Não foi possível instalar o pnpm")
    end
  end
  
  # Restaurar PATH original
  ENV['PATH'] = original_path
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task['assets:precompile'].enhance %w[before_assets_precompile]
