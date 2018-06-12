# A Script for Automatic Building Wine with  Staging and PBA patches

The script automatically clones newest Wine sources from official Wine Git repository. After that it clones newest Staging and PBA patches and applies them. Patched Wine is being built and installed to a directory specified by user.

## Brief Help
Tool for downloading, patching and building newest Wine with Staging and PBA patches.  
Arguments:  
**-d** - specify working directory;  
**-o** - scecify output directory;  
**-j** - scecify number of threads used for building Wine;  
**-c** - clear temporary files after successfull installation;  
**-h** - print help text.  

## Requirements:  

- **Git**;  
- **Wine build dependencies**  

## Run 
```
bash winebuilder.sh
```  
  
Barashkov A.A., 2018 
