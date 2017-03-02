require 'fileutils'
#Set Clonezilla image location (usually /home/partimag)
IMAGELOCATION = "/home/partimag/"
PWD = FileUtils.pwd()
folder = PWD.sub(IMAGELOCATION, "")
#Get manufacturer, model, and size from PWD
manufacturer, model, size = folder.split("/")

#Files to exclude from linking (copy these files instead)
excludeFromLN = ["sda-pt.sf"]

###########################################################
# Definition of drive options and number of blocks, using #
# 512B sectors.  Rule of thumb: Round DOWN to nearest     #
# 10,000 sectors to prevent issues with drives being too  #
# small                                                   #
###########################################################
diskSizes = {
  "128" => 250000000,
  "160" => 312500000,
  "250" => 488281250,
  "256" => 500000000,
  "500" => 976562500,
  "1000" => 1953125000
}


driveSchemes = ["3-partition (Second Partition Primary)", "Don't create the geometry for me, please"]
puts "What partition scheme is this unit?"
driveSchemes.each_with_index do |scheme, index|
  puts "#{index+1}) #{scheme}"
end
partScheme = gets.chomp.to_i

diskSizes.each do |diskSize, sectors|
  if size != diskSize && size.to_i < diskSize.to_i
    validResponse = false
    puts "Should I make an image of size: #{diskSize}GB? (y/n)"
    until validResponse == true
      response = gets.chomp.upcase
      validResponse = ["Y", "N"].include?(response)
      if validResponse == false
        puts "Care to try that again?"
      end
    end
    #Create folder
    if response == "Y"
        newFolder = "#{IMAGELOCATION}#{manufacturer}/#{model}/#{diskSize}"
        ###################################################
        # Create New Image Folders and Link/Copy Contents #
        ###################################################
        FileUtils.mkdir(newFolder)
        files = Dir.entries(PWD)
        files.delete("..")
        files.delete(".")
        files.each do |file|
          if excludeFromLN.include?(file)
            #Copy files that will change between images (drive geometry)
            FileUtils.cp("#{PWD}/#{file}", "#{newFolder}/#{file}")
          else
            #Link files that will not change between images (partclone images)
            FileUtils.ln("#{PWD}/#{file}", "#{newFolder}/#{file}")
          end
        end
        ###################################################
        # End of Create New Image Folders #################
        ###################################################

        ###################################################
        # Drive Geometry generation                       #
        ###################################################

        # Get sda-pt.sf and open it
        geometry = File.readlines("#{newFolder}/sda-pt.sf")

        ###################################################
        # Standard 3-Partition (Second Primary)           #
        # In this scheme, third partition start is        #
        # calculated from the end of the drive geometry   #
        # and second partition size is calculated as      #
        # third partition start sector minus second       #
        # partition start point.  Clonezilla will handle  #
        # the resizing natively with no issues            #
        ###################################################

        if partScheme == 1
          line = geometry[-1]
          thirdPartSize = line.scan(/size= *\d*/)[0].split(" ")[1].to_i
          puts sectors
          thirdPartStart = sectors-thirdPartSize
          geometry[-1] = line.gsub(/start= *\d*/, "start= #{thirdPartStart.to_s}")
          line = geometry[-2]
          secondPartStart = line.scan(/start= *\d*/)[0].split(" ")[1].to_i
          secondPartSize = thirdPartStart-secondPartStart
          geometry[-2] = line.gsub(/size= *\d*/, "size= #{secondPartSize.to_i}")
          File.open("#{newFolder}/sda-pt.sf", "w") do |file|
            file.puts geometry
          end

        end

        ###################################################
        # End of Standard 3-Partition (Second Primary)    #
        ###################################################

    end
  end
end
