Building the app should be pretty straightforward. All of the dependencies 
are located in the 'Vendor' group and the 'vendor' directory, and are built
as static libs. The only weird dependency is boost, and unfortunately I can't 
remember how I built it! It has something to do with the .jam file included 
in the root directory, and I think I built it under two architectures and
lipo'd each .lib together. If I can figure it out, I'll put it here. 

You should just be able to build the main DGSPhone target, and everything 
else should 'just work.' 