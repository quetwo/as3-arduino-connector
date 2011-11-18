/*
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is SerialANE.c
 *
 * The Initial Developer of the Original Code is Nicholas Kwiatkowski.
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 */

#include "SerialANE.h"

#include "stdio.h"
#include "pthread.h"
#include "stdlib.h"
#include "stdint.h"
#include "String.h"
#include "rs232.h"

#include "FlashRuntimeExtensions.h"

#ifdef _WIN32
  uint32_t isSupportedInOS = 1;
#else
  uint32_t isSupportedInOS = 0;
#endif

  FREContext dllContext;
  pthread_t ptrToThread;
  unsigned char buffer[4096];
  int bufferSize;
  int32_t comPort;
  int baud;
  int sentEvent;

  pthread_mutex_t safety = PTHREAD_MUTEX_INITIALIZER;


void *pollForData()
{

  unsigned char incomingBuffer[4096];
  int incomingBufferSize = 0;

  while(1)
    {
      Sleep(1000);   // used only for testing.  I want managable loops, not crazy ones.
      incomingBufferSize = PollComport(comPort,incomingBuffer,4095);
      if (incomingBufferSize > 0)
        {
          pthread_mutex_lock( &safety );
          memcpy(buffer+bufferSize,incomingBuffer,incomingBufferSize);
          bufferSize = bufferSize + incomingBufferSize;
          buffer[bufferSize] = 0;
          pthread_mutex_unlock( &safety);
        }

      if ((bufferSize > 0) && (sentEvent == 0))
        {
          FREDispatchStatusEventAsync(dllContext, (uint8_t*) incomingBuffer, (const uint8_t*) "INFO");
          sentEvent = 1;
        }
    }
    return NULL;
}


FREObject isSupported(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{

  FREObject result;
  FRENewObjectFromBool( isSupportedInOS, &result);
  return result;
}

FREObject getBytesAsArray(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
  FREObject result;

   FRENewObject((const uint8_t*) "Array", 0,  NULL, &result, NULL);
   FRESetArrayLength(result,bufferSize-1);

   FREObject myChar;
   int i;

   pthread_mutex_lock( &safety);
   for(i=0; i < bufferSize; i++)
     {
       FRENewObjectFromUTF8(1,(unsigned char *) buffer+i, &myChar);
       FRESetArrayElementAt(result, i, myChar);
     }

  bufferSize=0;
  sentEvent = 0;
  pthread_mutex_unlock( &safety);

  return result;
}

FREObject getBytesAsString(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
  FREObject result;

  pthread_mutex_lock( &safety);
    FRENewObjectFromUTF8(bufferSize,(unsigned char *) buffer, &result);
    bufferSize=0;
    sentEvent = 0;
  pthread_mutex_unlock( &safety);

  return result;
}

FREObject getBytesAsByteArray(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
  FREObject result;
  FREByteArray incomingBytes;

  FREAcquireByteArray(argv[0], &incomingBytes);

  pthread_mutex_lock( &safety);
    memcpy(incomingBytes.bytes,buffer,bufferSize);
    bufferSize=0;
    sentEvent = 0;
  pthread_mutex_unlock( &safety);

  FREReleaseByteArray( &incomingBytes);

  FRENewObjectFromBool(1, &result);
  return result;
}

FREObject sendString(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
  FREObject result;

  uint32_t lengthToSend;
  const uint8_t *dataToSend;
  int sendResult = 0;

  FREGetObjectAsUTF8(argv[0], &lengthToSend, &dataToSend);

  sendResult = SendBuf(comPort, (unsigned char *)dataToSend, lengthToSend);

  if (sendResult == -1)
    {
      FRENewObjectFromBool(0, &result);
    }
  else
    {
      FRENewObjectFromBool(1, &result);
    }
  return result;
}

FREObject sendByteArray(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
  FREObject result;
  FREByteArray dataToSend;
  int sendResult = 0;

  FREAcquireByteArray(argv[0], &dataToSend);

  sendResult = SendBuf(comPort, (unsigned char *)&dataToSend.bytes, dataToSend.length);

  FREReleaseByteArray(argv[0]);

  if (sendResult == -1)
    {
      FRENewObjectFromBool(0, &result);
    }
  else
    {
      FRENewObjectFromBool(1, &result);
    }
  return result;
}

FREObject setupPort(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
  FREObject result;
  int comPortError = 0;

  FREGetObjectAsInt32(argv[0], &comPort);
  FREGetObjectAsInt32(argv[1], &baud);

  bufferSize = 0;

  comPortError = OpenComport(comPort,baud);
  if (comPortError == 0)
    {
      Sleep(100);
      pthread_create(&ptrToThread, NULL, pollForData, NULL);
      FRENewObjectFromBool(1, &result);
    }
  else
    {
      FRENewObjectFromBool(0, &result);
    }

  return result;
}

void contextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctions, const FRENamedFunction** functions)
{
  *numFunctions = 7;
  FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * (*numFunctions));

  func[0].name = (const uint8_t*) "isSupported";
  func[0].functionData = NULL;
  func[0].function = &isSupported;

  func[1].name = (const uint8_t*) "getBytesAsArray";
  func[1].functionData = NULL;
  func[1].function = &getBytesAsArray;

  func[2].name = (const uint8_t*) "sendString";
  func[2].functionData = NULL;
  func[2].function = &sendString;

  func[3].name = (const uint8_t*) "setupPort";
  func[3].functionData = NULL;
  func[3].function = &setupPort;

  func[4].name = (const uint8_t*) "getBytesAsString";
  func[4].functionData = NULL;
  func[4].function = &getBytesAsString;

  func[5].name = (const uint8_t*) "sendByteArray";
  func[5].functionData = NULL;
  func[5].function = &sendByteArray;

  func[6].name = (const uint8_t*) "getBytesAsByteArray";
  func[6].functionData = NULL;
  func[6].function = &getBytesAsByteArray;

  *functions = func;

  dllContext = ctx;
  sentEvent = 0;
}

void contextFinalizer(FREContext ctx)
{
  pthread_cancel(ptrToThread);
  CloseComport(comPort);
  return;
}

void initializer(void** extData, FREContextInitializer* ctxInitializer, FREContextFinalizer* ctxFinalizer)
{
  *ctxInitializer = &contextInitializer;
  *ctxFinalizer = &contextFinalizer;
}

void finalizer(void* extData)
{
  return;
}

