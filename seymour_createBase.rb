require 'fileutils'
IMAGELOCATION = "/home/partimag/"
STOPCHAR = "S"
SIZES = [80, 120, 160, 250, 320, 256, 500, 1000].freeze

drive = "/dev/sda"

partitions = (1..5).to_a


driveSize = `lsblk -b | grep "sda " | grep -oE '[0-9]{3,}'`.chomp.to_i
humanReadableSize = driveSize / 1000.0 / 1000 / 1000
humanReadableSize = SIZES.map { |x| [x, (x - humanReadableSize).abs] }.to_h.min_by { |_size, distance| distance }[0]

location = ""
location << IMAGELOCATION
selection = ""
until selection == STOPCHAR do
  directory = Dir.entries(location)
  directory.delete(".")
  directory.delete("..")
  directory.sort!
  puts "Directory: #{location}"
  directory.each_with_index do |subdir, index|
    puts "#{(index+1).to_s}) #{subdir}"
  end
  puts "N) New Directory"
  puts "#{STOPCHAR}) Place Image Here"
  puts "Enter Selection"
  selection = gets.chomp.upcase
  if selection == "N"
    confirmed = false
    until confirmed == true do
      puts "Enter Directory Name"
      newFolder = gets.chomp
      puts "Create Directory #{newFolder}? (Y)es/(N)o/(C)ancel"
      confirmation = gets.chomp.upcase
      if ["Y", "C"].include?(confirmation)
        confirmed = true
      else
        confirmed = false
      end
    end
    if confirmation == "Y"
      location << "/#{newFolder}/"
      FileUtils.mkdir_p(location)
    end
  elsif selection.to_i
    location << "#{directory[(selection.to_i - 1)]}/"
  end
end

if selection == STOPCHAR
  location = location.sub("//", "/")
  system("i3-msg layout splitv")
  partitions.each do |partno|
    system("sudo ntfsfix -d #{drive}#{partno.to_s}")
  end
  system("xterm -e \"sudo ocs-sr -q2 -j -z0 -i 1000000000000000 -scs -p choose savedisk #{location.sub(IMAGELOCATION, "")}#{humanReadableSize} sda
\"")
  system("xterm -e \"cd #{location}/#{humanReadableSize}; sudo createimagetree\"")
end
