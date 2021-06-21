Orca
====

I. Prerequisites
-------------

- Orca relies heavily on the Cocoa frameworks, and will only compile and run on MacOS
- You must install any needed drivers before hardware accesses will work
- Openly available drivers are at svn://orca.physics.unc.edu/Drivers


II. Notes
---------

- As of April 2020, Orca has been moved from the svn server at UNC to GitHub
- The svn server is still maintained with read-only access, but the respository will no longer be updated
- Orca is now a 64 bit application by default.  The source code is available at https://github.com/unc-enap/Orca
- If you use OrcaRoot, it is available at https://github.com/unc-enap/OrcaRoot
- For more extensive GitHub instructions than what is provided below: https://help.github.com/en/github
- The [Orca website](http://orca.physics.unc.edu) provides details on using Orca and the hardware it interfaces with


III. Getting Started
---------------

1.  **Obtaining the source code**
- If you do not plan to make changes to the source code, you can obtain a local copy of the code from a terminal with:
```bash
git clone https://github.com/unc-enap/Orca
```
- Alternatively, you can launch a zip file download from the browser by selecting "Clone or download" from the URL.

2.  **Building the source code**

To launch the Xcode project builder and compile the code:
- Point the finder to the base directory of the code
- Double-click on Orca.xcodeproj
- Alternatively, from a terminal: "open Orca.xcodeproj"
- In the "Product" menu, select "Build"

3.  **Running Orca**
- In the Xcode "Project" menu, select "Run"
- By default, this will be in debug mode
- To leave debug mode, select "Detach from Orca" in the "Debug" menu of Xcode
- At this point Xcode can be closed
- Once Orca is running, Ctrl-click on the Orca icon in the dock and select "Options->Keep in Dock"
- To later launch the version of Orca just compiled, select the icon in the dock

4.  **Updating Orca**
- To update Orca from a terminal, go to the base directory of the source code, then:
```bash
git pull
```
- Then rebuild Orca from Xcode as above.
- Alternatively, the "Source Control" menu in Xcode has a "Pull" option which will update the code from the selected source.
The code must then be rebuilt in Xcode as above.  The icon in the dock will launch the most recently compiled version.

5.  **Orca notifications**

To receive notifications when there are updates or other conversations related to the Orca code:
- Go to https://github.com/unc-enap/Orca in a browser
- Select the "Watch" icon near the top right


IV.  Orca Development
---------------------

1.  **Creating a fork**

If you plan to make changes to the source code, instead of obtaining the source directly from the main branch as above:
- In a browser, log into your GitHub account
- Then go to: https://github.com/unc-enap/Orca
- Select the "Fork" icon in the top right
- Now follow the directions as above except when cloning the code use
```bash
git clone https://github.com/YOUR_USERNAME/Orca
```

2.  **Updating your fork**

To update your local fork from the base directory of the source code in a terminal (the first step only has to be done once):
```bash
git remote add upstream https://gitbhub.com/unc-enap/Orca
git pull upstream master
```

3.  **Committing changes**

As you edit your local copy of the code, make commits early and often as they are ready and tested with:
```bash
git commit [...]
```
where the last part of the command is the path to a single file or a space separated list of files.  For larger numbers of changed files, the -a flag can be used in place of the file list to commit all changes to tracked files.

This will automatically launch a text editor for you to enter a commit message.
The code will not be committed until the message in the editor is saved and closed.
To globally set the git editor of your choice, for say emacs:
git config --global core.editor "emacs"

For short commit messages, you can add them to the command line:
```bash
git commit -m "Your message here." [...]
```

4.  **Pushing changes**

After you have made one or a series of commits, push the changes to your forked repository:
```bash
git push
```
*Alternatively, you can conveniently pull, review, commit, and push changes using the Xcode "Source Control" menu.*

5.  **Creating a pull request**

  Now if you visit the URL for your repository in a browser, you will see your latest changes in the commit history.  If your changes are tested and ready to be incorporated into the master branch of Orca, then you can submit a pull request.  Before submitting a pull request, it is a good idea to update your fork and deal with any conflicts.  Then, from the URL of your fork of Orca:
- click on "New Pull Request"
- set base repository to unc-enap/Orca
- set the head repository to YOUR_USERNAME/Orca
- compare the changes on the base branch you want to merge to against the branch you want to pull changes from
- submit the pull request if the changes look good and there are no unresolved conflicts
- to see the status of your pull request, choose the "Pull requests" tab at unc-enap/Orca
- once your code is reviewed, the pull request may be accepted or changes will be suggested in the comments


V.  Running the 32 bit Version
------------------------------

Beginning with Xcode 10 on MacOS 10.14, 32 bit applications are no longer supported.  However, the older 32 bit version of Orca can be run prior to 10.15 by compiling with Xcode 9.  The 32 bit version of Orca is available at https://github.com/unc-enap/Orca32.

Running the 32 bit version is no longer recommended unless required by your system.  In general, only bug fixes will be implemented in the 32 bit version.


VI.  Obsolete SVN Instructions
------------------------------

As mentioned above, the repository on the old svn server will no longer be updated, and the repository is read-only.  Although it is not recommended, the out-of-date code can be obtained from the svn server.

To obtain the entire code base, drivers, etc from the svn server:
```bash
svn co svn://orca.physics.unc.edu
```

Note that on the svn server, Orca refers to the old 32 bit version while the git repository named Orca is the 64 bit version.
If you only need the 32 bit version of Orca:
```bash
svn co svn://orca.physics.unc.edu/Orca
```

If you only need the 64 bit version of Orca:
```bash
svn co svn://orca.physics.unc.edu/Orca64
```

For the obsolete plugin:
```bash
svn co svn://orca.physics.unc.edu/OrcaPlugin
```

OrcaRoot is also available on GitHub.  The version here will no longer be updated:
```bash
svn co svn://orca.physics.unc.edu/OrcaRoot
```


