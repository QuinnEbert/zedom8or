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
    send_cmd(4,cmd);
}
void VolumeUp(char *hostname) {
    char *a = (char *)"send_cmd";
    char *b = (char *)hostname;
    char *c = (char *)"8102";
    char *d = (char *)"VU";
    char *cmd[4] = {a,b,c,d};
    send_cmd(4,cmd);
}
void send_cmd(int argc, char **argv) {
    int sockfd, portno, n;
    struct sockaddr_in serveraddr;
    struct hostent *server;
    char *hostname;
    char buf[BUFSIZE];
    
    /* check command line arguments */
    if (argc != 4) {
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
    
    //FIXME: this should be settable via a parameter!!!
    int sentPkts = 0;
    for (sentPkts = 0; sentPkts < 5; sentPkts++) {
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
    close(sockfd);
}