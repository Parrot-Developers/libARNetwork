//
//  AppDelegate.m
//  test1
//
//  Created by Nicolas Payot on 09/11/12.
//  Copyright (c) 2012 Parrot SA. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate




/*****************************************
 *
 * 			include file :
 *
 ******************************************/

#include <stdlib.h>
#include <libSAL/print.h>
#include <libSAL/thread.h>

#include <string.h>

#include <libNetwork/frame.h>
#include <libNetwork/manager.h>
#include <libSAL/socket.h>

#include <unistd.h>

/*****************************************
 *
 * 			define :
 *
 ******************************************/

#define NUMBER_DATA_SENT 5
#define SENDING_SLEEP_TIME_US 50000
#define RECEIVER_TIMEOUT_SEC 5
#define FIRST_CHAR_SENT 'A'
#define FIRST_INT_ACK_SENT 100

#define RECV_TIMEOUT_MS 10
#define PORT1 5551
#define PORT2 5552
#define ADRR_IP "127.0.0.1"

#define SEND_BUFF_SIZE 256
#define RECV_BUFF_SIZE 256


/** define of the ioBuuffer identifiers */
typedef enum eID_BUFF
{
	ID_CHAR_DATA = 5,
	ID_INT_DATA_WITH_ACK,
	ID_INT_DATA
}eID_BUFF;


/*****************************************
 *
 * 			implementation :
 *
 ******************************************/

- (void)test1
{
    
    /** local declarations */
	network_manager_t* pManager1= NULL;
	network_manager_t* pManager2= NULL;
    sal_thread_t thread_send1 = NULL;
	sal_thread_t thread_recv1 = NULL;
	sal_thread_t thread_send2 = NULL;
	sal_thread_t thread_recv2 = NULL;
	
	int ii = 0;
	int error = 0;
	char chData = 0;
	int intData = 0;
	
	network_paramNewIoBuffer_t paramInputNetwork1[2];
	network_paramNewIoBuffer_t paramOutputNetwork1[1];
	
	network_paramNewIoBuffer_t paramInputNetwork2[1];
	network_paramNewIoBuffer_t paramOutputNetwork2[2];
	
    /** initialization of the buffer parameters */
	/** --- network 1 --- */
	
	/** input ID_CHAR_DATA int */
    NETWORK_ParamNewIoBufferDefaultInit( &(paramInputNetwork1[0]) );
	paramInputNetwork1[0].id = ID_CHAR_DATA;
	paramInputNetwork1[0].dataType = network_frame_t_TYPE_DATA;
	paramInputNetwork1[0].buffSize = 1;
	paramInputNetwork1[0].buffCellSize = sizeof(char);
	paramInputNetwork1[0].overwriting = 1;
	
	/** input ID_INT_DATA_WITH_ACK char */
    NETWORK_ParamNewIoBufferDefaultInit( &(paramInputNetwork1[1]) );
	paramInputNetwork1[1].id = ID_INT_DATA_WITH_ACK;
	paramInputNetwork1[1].dataType = network_frame_t_TYPE_DATA_WITH_ACK;
	paramInputNetwork1[1].sendingWaitTime = 2;
	paramInputNetwork1[1].ackTimeoutMs = 10;
	paramInputNetwork1[1].nbOfRetry = -1/*20*/;
	paramInputNetwork1[1].buffSize = 5;
	paramInputNetwork1[1].buffCellSize = sizeof(int);
	paramInputNetwork1[1].overwriting = 0;
	
	/** output ID_INT_DATA int */
    NETWORK_ParamNewIoBufferDefaultInit( &(paramOutputNetwork1[0]) );
	paramOutputNetwork1[0].id = ID_INT_DATA;
	paramOutputNetwork1[0].dataType = network_frame_t_TYPE_DATA;
	paramOutputNetwork1[0].buffSize = 10;
	paramOutputNetwork1[0].buffCellSize = sizeof(int);
	paramOutputNetwork1[0].overwriting = 1;
	
	/** ----------------------------- */
	
	/**--- network 2 --- */
	
	/** input ID_INT_DATA char */
    NETWORK_ParamNewIoBufferDefaultInit( &(paramInputNetwork2[0]) );
	paramInputNetwork2[0].id = ID_INT_DATA;
	paramInputNetwork2[0].dataType = network_frame_t_TYPE_DATA;
	paramInputNetwork2[0].sendingWaitTime = 2;
	paramInputNetwork2[0].buffSize = 2;
	paramInputNetwork2[0].buffCellSize = sizeof(int);
	paramInputNetwork2[0].overwriting = 1;
	
	/**  output ID_CHAR_DATA int */
    NETWORK_ParamNewIoBufferDefaultInit( &(paramOutputNetwork2[0]) );
	paramOutputNetwork2[0].id = ID_CHAR_DATA;
	paramOutputNetwork2[0].dataType = network_frame_t_TYPE_DATA;
	paramOutputNetwork2[0].sendingWaitTime = 3;
	paramOutputNetwork2[0].buffSize = 1;
	paramOutputNetwork2[0].buffCellSize = sizeof(char);
	paramOutputNetwork2[0].overwriting = 1;
	
	/** output ID_INT_DATA_WITH_ACK int */
    NETWORK_ParamNewIoBufferDefaultInit( &(paramOutputNetwork2[1]) );
	paramOutputNetwork2[1].id = ID_INT_DATA_WITH_ACK;
    paramOutputNetwork2[1].dataType = network_frame_t_TYPE_DATA_WITH_ACK;
	paramOutputNetwork2[1].buffSize = 5;
	paramOutputNetwork2[1].buffCellSize = sizeof(int);
	paramOutputNetwork2[1].overwriting = 0;
	
	//-----------------------------
    
    NSLog(@" -- libNetWork Test Bench auto -- \n");
	
	/** create the Manger1 */
    
	pManager1 = NETWORK_NewManager( RECV_BUFF_SIZE, SEND_BUFF_SIZE, 2, paramInputNetwork1, 1, paramOutputNetwork1);
    
    error = NETWORK_ManagerScoketsInit(pManager1, ADRR_IP, PORT1, PORT2, RECEIVER_TIMEOUT_SEC);
   NSLog(@"pManager1 error initScoket = %d", error);
    
    /** create the Manger2 */
	pManager2 = NETWORK_NewManager( RECV_BUFF_SIZE, SEND_BUFF_SIZE, 1, paramInputNetwork2, 2, paramOutputNetwork2);
    
    error = NETWORK_ManagerScoketsInit(pManager2, ADRR_IP, PORT2, PORT1, RECEIVER_TIMEOUT_SEC);
    NSLog(@"pManager2 error initScoket = %d", error);
	
	NSLog(@"main start \n");
	
	
    /** create the threads */
	sal_thread_create(&(thread_recv2), (sal_thread_routine) NETWORK_ManagerRunReceivingThread, pManager2);
	sal_thread_create(&(thread_recv1), (sal_thread_routine) NETWORK_ManagerRunReceivingThread, pManager1);
	
	sal_thread_create(&thread_send1, (sal_thread_routine) NETWORK_ManagerRunSendingThread, pManager1);
	sal_thread_create(&thread_send2, (sal_thread_routine) NETWORK_ManagerRunSendingThread, pManager2);
    
    
    /** loop sending data */
    for(ii = 0; ii < NUMBER_DATA_SENT; ii++)
    {
		chData = FIRST_CHAR_SENT + ii;
		NSLog(@" send char: %c \n",chData);
		error = NETWORK_ManagerSendData(pManager1, ID_CHAR_DATA, &chData);
		
		if( error )
		{
			printf(" error send char \n");
		}
        
		intData = FIRST_INT_ACK_SENT + ii;
		NSLog(@" send int: %d \n",intData);
		error = NETWORK_ManagerSendData(pManager1, ID_INT_DATA_WITH_ACK, &intData);
		
		if( error )
		{
			NSLog(@" error send int ack \n");
		}
		
        usleep(SENDING_SLEEP_TIME_US);
    }
	
	NSLog(@" -- stop-- \n");
	
	/** stop all therad */
    NETWORK_ManagerStop(pManager1);
	NETWORK_ManagerStop(pManager2);
	
	NSLog(@"wait ... \n");
	
	//kill all thread
	if(thread_send1 != NULL)
	{
		sal_thread_join(&(thread_send1), NULL);
	}
	if(thread_send2 != NULL)
	{
		sal_thread_join(&(thread_send2), NULL);
	}
	
	if(thread_recv1 != NULL)
	{
		sal_thread_join(&(thread_recv1), NULL);
	}
	
	if(thread_recv2 != NULL)
	{
		sal_thread_join(&(thread_recv2), NULL);
	}
    
	
    /** checking */
    ii = 0;
	NSLog(@"\n the last char transmitted:\n");
    while( ! NETWORK_ManagerReadData(pManager2, ID_CHAR_DATA, &chData) )
    {
        ++ii;
        printf("- %c \n", chData);
        /** check values */
        error = error || ( chData != ( FIRST_CHAR_SENT + (NUMBER_DATA_SENT - 1) ) );
    }
    /** check nb data */
	error = error || ( ii != 1) ;
    
	NSLog(@"\n the integers transmitted:\n");
    ii = 0;
    while( ! NETWORK_ManagerReadData(pManager2, ID_INT_DATA_WITH_ACK, &intData) )
    {
        NSLog(@"- %d \n", intData);
        /** check values */
        error = error || ( intData != FIRST_INT_ACK_SENT + ii);
        ++ii;
    }
    /** check nb data */
    error = error || ( ii != 5) ;
	
	NSLog(@"\n");
    
    if(error)
    {
        NSLog(@"Bad result of the test bench \n");
    }
    else
    {
        NSLog(@"Good result of the test bench \n");
    }
    
    
    
	NSLog(@"end \n");
    
    /** delete */
	NETWORK_DeleteManager( &pManager1 );
	NETWORK_DeleteManager( &pManager2 );
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [self test1];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
