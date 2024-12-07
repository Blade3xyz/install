#!/usr/bin/env ruby
# frozen_string_literal: true

BLADE3_REMOTE = "https://github.com/Blade3xyz/blade3"
INSTALLER_REMOTE = "https://github.com/Blade3xyz/installer"
INSTALL_DIR = "/usr/lib/blade3"
CONFIG_DIR = "/etc/blade3"
CRYPTO_DIR = "#{CONFIG_DIR}/crypto"
BIN_DIR = "/usr/bin"
LICENSE_URL = "https://raw.githubusercontent.com/Blade3xyz/blade3/refs/heads/master/COPYING"
LICENSE_FILE = "/tmp/blade3.installer.COPYING"

SUDO = "sudo"

module TTY
  module_function

  def blue
    bold 34
  end

  def red
    bold 31
  end

  def reset
    escape 0
  end

  def bold(code = 39)
    escape "1;#{code}"
  end

  def underline
    escape "4;39"
  end

  def escape(code)
    "\033[#{code}m" if STDOUT.tty?
  end
end

def log(message)
  puts "#{TTY.blue}%#{TTY.bold} #{message}#{TTY.reset}"
end

def whereis(tool_name)
  log "Checking for #{tool_name}..."

  result = `which #{tool_name}` 

  if result.include? "which: no"
    return "none"
  end

  # Remove newline
  result = result.chomp

  result
end

def sys(command)
  log "Executing '#{command}'"

  unless system(command)
    log "Failed to execute '#{command}', aborting!"
    exit(1)
  end
end

def license_check
  log "Downloading license from #{LICENSE_URL}..."

  Kernel.system("curl -#L #{LICENSE_URL} -o #{LICENSE_FILE}")

  # Prepend information to the file
  rd = IO.read LICENSE_FILE
  IO.write(LICENSE_FILE, "** Please read over the GPLv3 license, and press Q when complete **\n\n\n" + rd)

  # Use less
  system("less #{LICENSE_FILE}")

  log "Do you agree to the terms of the GPLv3 license? [Y/n]"
  agree = gets.chomp

  if agree == "y" || agree == "Y"
    return true
  elsif agree == "n" || agree == "N"
    return false
  else
    return false
  end
end

log "Blade3 installer"
log "----------------"
log "Remote: #{BLADE3_REMOTE}"
log "Installation dir  : #{INSTALL_DIR}"
log "Configuration dir : #{CONFIG_DIR}"
log "Cryptography dir  : #{CRYPTO_DIR}"
puts ""
log "This program will install blade3 onto this machine"
log "Press ENTER to begin installation"

gets

unless license_check
  log "User did not agree to the license! Aborting installer"
  exit(0)
end

log "Checking for programs..."

git = whereis("git")
sudo = whereis(SUDO)
gem = whereis("gem")
bundler = whereis("bundler")

if git == 'none'
  abort "Git not installed! Cannot continue"
end

if sudo == 'none'
  abort "#{SUDO.capitialize} not found! Cannot elevate to root user"
end

if gem == 'none'
  abort 'Rubygems not found! Cannot install dependencies'
end

if bundler == 'none'
  abort "Bundler not found! Cannot install dependencies"
end

if SUDO == "sudo"
  log "Refreshing sudo timestamp..."
  sys("#{sudo} -v")
end

log "Downloading and installing blade3..."

sys("#{sudo} #{git} clone #{BLADE3_REMOTE} #{INSTALL_DIR}")

log "Creating configuration directories..."

sys("#{sudo} mkdir -p #{CONFIG_DIR}")
sys("#{sudo} mkdir -p #{CRYPTO_DIR}")

log "Copying configurations..."

sys("#{sudo} cp -f #{INSTALL_DIR}/user/server_config.rb #{CONFIG_DIR}/")
sys("#{sudo} cp -f #{INSTALL_DIR}/user/client_config.rb #{CONFIG_DIR}/")

log "Changing ownership of files"
sys("#{sudo} chown $USER #{INSTALL_DIR}/Gemfile.lock")
sys("#{sudo} chmod +x #{INSTALL_DIR}/blade3_client.rb")


log "Install dependencies via bundler"
Dir.chdir INSTALL_DIR

sys("#{bundler} install")

log "Symlinking binaries"

sys("#{sudo} ln -s #{INSTALL_DIR}/blade3_server.rb #{BIN_DIR}/blade3-server")
sys("#{sudo} ln -s #{INSTALL_DIR}/blade3_client.rb #{BIN_DIR}/blade3-client")

log "Cleaning up"
File.delete(LICENSE_FILE)

log "Blade3 installed!"
puts "For more information visit https://blade3.xyz"
puts "For information on how to update see https://blade3.xyz/update"
puts "This installers source code is located at #{INSTALLER_REMOTE}"
puts "If you like this project star it on GitHub at #{BLADE3_REMOTE}"
