# Ubuntu 14 LAMP Stack using Vagrant
This stack comes with:

- PHP 5.6
- MySQL 5.6
- phpMyAdmin
- Apache 2.4
- Composer
- An AWS credentials file template
- Ubuntu 14 
- An .htaccess template file inside for vanity URL's

## Installation
Just clone this repo to your working vagrant directory, open your command line to the new directory (where the Vagrantfile is found) and type `vagrant up`. It should download Ubuntu 14 and set up your local environment for you.

When complete, open your browser and go to `localhost:1234` to view your new site.

## Additional
You can setup your MySQL database by putting .sql files inside the `sql-setup` directory. The files are executed in alphabetical order, so applying a number to the start of the file name is a good idea. A sample .sql file is provided.

A default `index.php` is created. It's just a "Hello World" page. If you see it, your server is working.

A `phpinfo.php` page is created as well, so you can see what PHP setup.

phpMyAdmin can be accessed by going to `localhost:1234/phpmyadmin/`.

## Credentials
Your MySQL and phpMyAdmin credentials are `root / root`. 

Your SSH credentials are `vagrant / vagrant`. 

To SSH into your server: Hostname is `127.0.0.1` with port `2222`. Your private authentication key can be found at `~/YOUR_DIR/.vagrant/machines/default/virtualbox/private_key`

## Basic Customization
Want to change the port? Open the `Vagrantfile` and change:

`host: 1234` to `host: your_port_number`

Need more or less memory? Default memory is `2048`mb. Open `Vagrantfile` and change:

`"memory", "2048"` to `"memory", "1024"` - the `2048` and `1024` represent the number of mb's to offer the server. MySQL 5.6 typically requires 2048mb with Vagrant on Windows.

Looking to change, add or remove AWS credentials? The file is located at `/home/.aws/credentials` inside the virtual server. Or you can open `provision.sh` and modify lines 45 to 53 and run `vagrant provision` to make the changes.

## Contributions 
Feel free to branch off and add more to this setup. Right now it's quite basic and does the trick.
