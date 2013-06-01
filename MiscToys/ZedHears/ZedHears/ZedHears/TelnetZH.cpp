//
//  TelnetZH.cpp
//  ZedHears
//
//  Created by Quinn Ebert on 5/27/13.
//  Copyright (c) 2013 Quinn Ebert. All rights reserved.
//

#import "TelnetZH.h"

/*
 * error - wrapper for perror
 */
void error(char *msg) {
    perror(msg);
    exit(0);
}

void VolumeDn(char *hostname) {
    char *a = (char *)"send_cmd";
    char *b = (char *)hostname;
    char *c = (char *)"8102";
    char *d = (char *)"VD";
    char *cmd[4] = {a,b,c,d};
    char result[BUFSIZ];
    send_cmd(4,cmd,result);
}
void VolumeUp(char *hostname) {
    char *a = (char *)"send_cmd";
    char *b = (char *)hostname;
    char *c = (char *)"8102";
    char *d = (char *)"VU";
    char *cmd[4] = {a,b,c,d};
    char result[BUFSIZ];
    send_cmd(4,cmd,result);
}
// Request percent of maximum volume currently seen set on the 1022-K (this is
// gathered by equating the 81 distinct volume levels to the closest integers
// on a 100% scale, basically, multiplying the numeric volume setting from 0
// to 80 by 1.25 and rounding the result to the nearest integer)
// Returns current volume percent as string on OK or false (boolean) on error
long VolumePct(char *hostname) {
    float cv = (float)VolumeVal(hostname);
    return lroundf((cv*1.25));
}
int VolumeVal(char *hostname) {
    char *a = (char *)"send_cmd";
    char *b = (char *)hostname;
    char *c = (char *)"8102";
    char *d = (char *)"?V";
    char *e = (char *)"1";
    char *cmd[5] = {a,b,c,d,e};
    char result[BUFSIZ];
    send_cmd(5,cmd,result);
    char valStr[4] = {result[3],result[4],result[5],'\0'};
    int returns = (int)((((atoi(valStr))-1)/2));
    return returns;
}
void send_cmd(int argc, char **argv, char *ret) {
    int sockfd, portno, n;
    struct sockaddr_in serveraddr;
    struct hostent *server;
    char *hostname;
    char buf[BUFSIZE];
    
    /* check command line arguments */
    if (argc < 4) {
        fprintf(stderr,"usage: %s <hostname> <port> <command>\n", argv[0]);
        exit(0);
    }
    hostname = argv[1];
    portno = atoi(argv[2]);
    
    //printf("Send command \"%s\" to \"%s\" on port \"%s\"!\n",argv[3],argv[1],argv[2]);
    
    /* socket: create the socket */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0)
        error((char *)"ERROR opening socket");
    
    /* gethostbyname: get the server's DNS entry */
    server = gethostbyname(hostname);
    if (server == NULL) {
        fprintf(stderr,"ERROR, no such host as %s\n", hostname);
        exit(0);
    }
    
    /* build the server's Internet address */
    bzero((char *) &serveraddr, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    bcopy((char *)server->h_addr,
          (char *)&serveraddr.sin_addr.s_addr, server->h_length);
    serveraddr.sin_port = htons(portno);
    
    /* connect: create a connection with the server */
    if (connect(sockfd, (const struct sockaddr *)&serveraddr, (socklen_t)sizeof(serveraddr)) < 0)
        error((char *)"ERROR connecting");
    
    /* get message line from the user */
    //printf("Please enter msg: ");
    //bzero(buf, BUFSIZE);
    //fgets(buf, BUFSIZE, stdin);
    
    int sentPkts = 0;
    int sendPkts = 5;
    if (argc > 4) sendPkts = atoi(argv[4]);
    for (sentPkts = 0; sentPkts < sendPkts; sentPkts++) {
        /* send the message line to the server */
        n = (int)write(sockfd, argv[3], strlen(argv[3]));
        if (n < 0)
            error((char *)"ERROR writing to socket");
        n = (int)write(sockfd, "\r\n", strlen("\r\n"));
        if (n < 0)
            error((char *)"ERROR writing to socket");
    }
    
    /* --->pretend to<--- print the server's reply */
    bzero(buf, BUFSIZE);
    n = (int)read(sockfd, buf, BUFSIZE);
    if (n < 0)
        error((char *)"ERROR reading from socket");
    //printf("Echo from server: %s", buf);
    strcpy(ret, (const char *)buf);
    close(sockfd);
    usleep(200000);
}