Control fluidsynth settings for one midi keyboard using another midi keyboard for the pianomonster project. 
There are much, much more sensible ways of doing this, but this works using only things availible in ubuntu's `apt-get` and can run unsupervised, which is fairly handy.


you will need to install

`sudo apt-get install libportmidi-dev`


for good fluidsynth sound, give it permission to set high priority in `/etc/security/limits.conf` 

```
@audio       soft    rtprio   100
@audio       hard    rtprio   100
```

and add yourself to the audio group `sudo usermod -a -G  audio $USER`