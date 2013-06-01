//
//  TelnetZH.h
//  ZedHears
//
//  Created by Quinn Ebert on 5/27/13.
//  Copyright (c) 2013 Quinn Ebert. All rights reserved.
//

//#ifndef __ZedHears__TelnetZH__
//#define __ZedHears__TelnetZH__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define BUFSIZE 1024

void VolumeDn(char *hostname);
void VolumeUp(char *hostname);
long VolumePct(char *hostname);
int VolumeVal(char *hostname);
void send_cmd(int argc, char **argv, char *ret);

//#endif /* defined(__ZedHears__TelnetZH__) */
