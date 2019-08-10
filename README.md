# graphcool-export
A fault-tolerant exporter for Graph.cool data

Graph.cool has an API for exporting all of your data, but the script that is provided in the default command line tool does not do a great job of recovering from errors. Sometimes, you try to export, and you will occasionally get an error from their API proxy, the export fails, and the current values of the cursor are lost.

This script solves that problem by writing the current state of the cursor to a file, so you can pause or recover from failed exports.

This is a simple Ruby script, and requires a working Ruby setup with Bundler installed. Clone the repo, and then:

    bundle install
    bundle exec ruby ./export.rb --project <your project id> --token "<your token, with quotes around it> --path <the folder name you want to export to, relative to this directory> 
    
You can get a valid token from https://console.graph.cool 

The script is very chatty, and exports the verbatim response body for each call into a folder called 'data' under each export folder that you create.

You can then parse these JSON files as you like with your own scripts.
