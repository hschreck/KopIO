require 'fileutils'
#Set Clonezilla image location (usually /home/partimag)
IMAGELOCATION = "/home/partimag/"
PWD = FileUtils.pwd()
folder = PWD.sub(IMAGELOCATION, "")
#Get manufacturer, model, and size from PWD
locationArray = folder.split("/")
size = locationArray[-1] # last dir of PWD should be size

#Files to exclude from linking (copy these files instead)
excludeFromLN = ["sda-pt.sf"]

###########################################################
# Definition of drive options and number of blocks, using #
# 512B sectors.  Rule of thumb: Round DOWN to nearest     #
# 10,000 sectors to prevent issues with drives being too  #
# small                                                   #
###########################################################
diskSizes = {
  #80GB drives => 156,000,000 for reference when creating images
  "120" => 234000000,
  "160" => 312500000,
  "180" => 351500000,
  "250" => 488281250,
  "256" => 500000000,
  "320" => 624950000,
  "500" => 976562500,
  "1000" => 1953125000
}


driveSchemes = ["3-partition (Second Partition Primary)", "4-partition (Second Partition Primary)", "Don't create the geometry for me, please"]
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
        location = locationArray[0..-2]
        presentLocation = ""
        location.each do |dir|
          presentLocation << "#{dir}/"
        end
        newFolder = "#{IMAGELOCATION}#{presentLocation}#{diskSize}"
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
          puts "Recreating image geometry to match..."
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
        if partScheme == 2
          puts "Recreating image geometry to match..."
          line = geometry[-1]
          #get size of last partition
          fourthPartSize = line.scan(/size= *\d*/)[0].split(" ")[1].to_i
          puts sectors
          #set start of last partition
          fourthPartStart = sectors-fourthPartSize
          geometry[-1] = line.gsub(/start= *\d*/, "start= #{fourthPartStart.to_s}")
          #get size of next to last partition
          line = geometry[-2]
          thirdPartSize = line.scan(/size= *\d*/)[0].split(" ")[1].to_i
          thirdPartStart = fourthPartStart - thirdPartSize
          geometry[-2] = line.gsub(/start= *\d*/, "start= #{thirdPartStart.to_s}")
          #second (primary) partition
          line = geometry[-3]
          secondPartStart = line.scan(/start= *\d*/)[0].split(" ")[1].to_i
          secondPartSize = thirdPartStart-secondPartStart
          geometry[-3] = line.gsub(/size= *\d*/, "size= #{secondPartSize.to_i}")
          File.open("#{newFolder}/sda-pt.sf", "w") do |file|
            file.puts geometry
          end

        end
        system("diff sda-pt.sf ../#{diskSize.to_s}/sda-pt.sf")
        case $?.exitstatus
        when 0
          puts "Files are the same - failure"
        when 1
          puts "Files are different - success"
        end
    end
  end
end
