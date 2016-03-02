# mkFreeIPA
Make a persistent FreeIPA docker container PDQ


### Usage
`make temp` will make a temporary ephemeral fresh mysql instance

`make templogs` to watch the mysql process startup and initialize its databases

when this finishes (not before) you can then
`make grab` which will make a `datadir` in the current directory and copy out `/data` out
of the temporary container to be used in a persistent setup

`make rmtemp` will clean up our temporary containers, but will not delete the `datadir`

`make prod` will then use the `datadir` and start up our container in persistent mode
