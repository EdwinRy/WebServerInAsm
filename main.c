#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/socket.h>

#define REQUEST_BUFFER_SIZE 1000

struct addrinfo* getHostInfo(char* port)
{
    struct addrinfo socketHints = {0};
    socketHints.ai_flags = AI_PASSIVE;
    socketHints.ai_family = AF_INET;
    socketHints.ai_socktype = SOCK_STREAM;

    struct addrinfo *hostInfo;
    int errorCode = getaddrinfo(NULL, port, &socketHints, &hostInfo);
    if(errorCode)
    {
        printf("Error whilst getting address info: %s\n", 
            gai_strerror(errorCode));
        return NULL;
    }
    else
    {
        return hostInfo;
    }
}

// Return socket file descriptor
int bindSocket(struct addrinfo *addressInfo)
{
    int sockfd = socket(
                        addressInfo->ai_family, 
                        addressInfo->ai_socktype, 
                        addressInfo->ai_protocol);

    if(sockfd < 0) printf("Error: could not open socket\n");
    

    int socketOpt = 1;
    int setSocketOptionStatus = 
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &socketOpt, sizeof(int));
    
    if(setSocketOptionStatus < 0)
        printf("Error: could not set socket option\n");
    
    printf("%i\n", addressInfo->ai_addr);

    int bindStat = bind(sockfd, addressInfo->ai_addr, addressInfo->ai_addrlen);

    if(bindStat < 0) printf("Error: could not bind socket\n");

    freeaddrinfo(addressInfo);

    return sockfd;
}

void serveRequest(int req)
{
    char buffer[REQUEST_BUFFER_SIZE];
    char *method;
    char *url;
    int reqSize;

    recv(req, buffer, REQUEST_BUFFER_SIZE, 0);
    method = strtok(buffer, " ");

    // Handle GET request
    if(strcmp(method, "GET") == 0)
    {
        url = strtok(NULL, " ");

        // Strip beginning slash
        if(url[0] == '/') url++;

        // Send requested file
        FILE *f = fopen(url, "r");
        while(fgets(buffer, REQUEST_BUFFER_SIZE, f))
        {
            send(req, buffer, strlen(buffer), 0);
            memset(buffer, 0, REQUEST_BUFFER_SIZE);
        }
        fclose(f);
    }

    // Handle SET request
    else if(strcmp(method, "SET") == 0)
    {

    }

    //Ignore other
    else return;
    

}

int main()
{
    char* port = "4200";
    unsigned int backlogQueueLength = 20;


    struct addrinfo *addressInfo = getHostInfo("4200");
    int sockfd = bindSocket(addressInfo);

    if(listen(sockfd, backlogQueueLength) < 0)
        printf("Error: could not listen at socket\n");

    printf("listening on port %s\n", port);

    int newSocketFd;
    struct sockaddr_in clientAddr;
    int clientSize = sizeof(clientAddr);
    for(;;)
    {
        newSocketFd = 
            accept(sockfd, (struct sockaddr*) &clientAddr, &clientSize);

        if(newSocketFd < 0) printf("Error on connection accept\n");

        serveRequest(newSocketFd);
        close(newSocketFd);
    }

    close(sockfd);


    return 0;
}