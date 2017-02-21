# Seymour

Seymour is a set of simple Ruby scripts used to create multiple differently-sized Clonezilla drive images from a single small base image.

## Why is this useful?
If you need to image multiple units of a model with different size drives, Clonezilla offers relatively few options.

Proportional resizing will cause some really poor results when you're going from a very small image to a very large image.
Who wants a 100GB+ recovery drive?

Creating a specific image for every drive size is viable, but it will require a lot of storage space.  One of the base images
I've been using during testing is 40GB, and I need seven different sizes available - that's 280GB for a single model, and we have many models we sell, to say nothing of the variations between operating system offerings.

Instead, Seymour allows you to create a set of images using the base image.  It uses hard links to the image files to save space, and can optionally automatically generate the drive geometry specification that Clonezilla uses to create partition tables.

## How do I use this?
### seymour_gen.rb
Copy the script to a location on the machine you use to store the images.

Change into the directory that contains the image you wish to use as a base image.

Run the script *as root* (````sudo ruby seymour_gen.rb````, for example) and follow the prompts
