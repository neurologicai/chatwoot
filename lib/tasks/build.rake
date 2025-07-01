# ref: https://github.com/rails/rails/issues/43906#issuecomment-1094380699
# https://github.com/rails/rails/issues/43906#issuecomment-1099992310
task before_assets_precompile: :environment do
  # Garantir que pnpm esteja disponível no PATH
  original_path = ENV['PATH']
  ENV['PATH'] = "/usr/local/bin:/usr/local/lib/node_modules/.bin:#{original_path}"
  
  puts "=== Debugging PATH and pnpm availability ==="
  puts "PATH: #{ENV['PATH']}"
  puts "pnpm location: #{`which pnpm 2>/dev/null`.strip}"
  puts "pnpm version: #{`pnpm --version 2>/dev/null`.strip}"
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
    if system('npm install -g pnpm@10.2.0')
      puts "✅ pnpm instalado, tentando novamente..."
      system('pnpm install') || abort("❌ Falha ao executar pnpm install")
      system('echo "-------------- Bulding SDK for Production --------------"')
      system('pnpm run build:sdk') || abort("❌ Falha ao executar pnpm run build:sdk")
      system('echo "-------------- Bulding App for Production --------------"')
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
