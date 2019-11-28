# Ona Data Science Server
Portable R environment for running the Ona asobahousing models.  Includes bash script to set up R, install a few R packages, and get Rstudio Server running on ubuntu.  Also includes files necessary for various data ingestion APIs and sources

## Accessing the repo

You can access ```.Renviron``` via your R console or within the RStudio IDE:
```usethis::edit_r_environ()```

Put the PAT in your .Renviron file. Have a line that looks like this:

```GITHUB_PAT=<personal access token>```

Your .Renviron file should pop up in your editor. Add your GITHUB_PAT as above, save and close it.  Put a line break at the end. If you’re using an editor that shows line numbers, there should be two lines, where the second one is empty.

Restart R (Session > Restart R in the RStudio menu bar), as environment variables are loaded from .Renviron only at the start of an R session. Check that the PAT is now available like so:

```Sys.getenv("GITHUB_PAT")```

You should see your PAT print to screen.

Now commands you run from the devtools package, which consults GITHUB_PAT by default, will be able to access private GitHub repositories to which you have access, and you can install them with ```devtools::install_github('username/reponame')```.  With this set up, you will now be able to run the server install scripts.


