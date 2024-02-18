#include <exec/interrupts.h>
#include <hardware/intbits.h>
#include <devices/input.h>
#include <devices/inputevent.h>
#include <clib/exec_protos.h>
#include <clib/input_protos.h>
#include <clib/dos_protos.h>
#include <dos/dos.h>
#include <stdio.h>

#include "newmouse.h"
#include "mouSTer_protocol.h"

#define xstr(s) str(s)
#define str(s) #s

extern void mouSTerVBinterrupt(); 
void SendEvent(UWORD event);
int setup();
void cleanup();

void PrintBin(UBYTE i);

struct {
    UBYTE head;			// circullar buffer head 	cb_head = $00
    UBYTE tail;		    // circullar buffer tail 	cb_tail = $01
	ULONG signal;		// signal				 	cb_sign = $02
    struct Task *task;	// pointer to task struct	cb_task = $06
    UBYTE cbuffer[256]; // circullar buffer 		cb_buff = $0A
} mouSTerData = {0};	// make sure the struct is filled with null's. Just in case.

struct Interrupt VBInterrupt = {
	{	0,								// struct  Node *ln_Succ;	/* Pointer to next (successor) */
		0,								// struct  Node *ln_Pred;	/* Pointer to previous (predecessor) */
		NT_INTERRUPT,					// UBYTE   ln_Type;
		0,  							// BYTE    ln_Pri;			/* Priority, for sorting */
		"mouSTer wheel mouse Driver"	// char *ln_Name;			/* ID string, null terminated */
	},									// Node
	&mouSTerData,						// APTR    is_Data;		    /* server data segment  */
	mouSTerVBinterrupt					// VOID    (*is_Code)();	/* server code entry    */
};

struct IOStdReq   *InputIO;
struct MsgPort    *InputMP;

struct InputEvent MouseEvent = 
	{	.ie_EventAddress 	= NULL,
		.ie_NextEvent		= NULL,
		.ie_Class			= IECLASS_RAWKEY,
		.ie_SubClass		= 0,
		.ie_X				= 0,
		.ie_Y				= 0,	
	};

UBYTE intsignal;
UBYTE newstate;
UBYTE laststate = 0;
UBYTE tmp;
UBYTE tmpstate;

//Version string required by installer
const char versionString[] = "$VER: mouSTer.driver "xstr(BUILD_VERSION)" ("__DATE__") (c) 2024 willy.\npress CTRL-C to exit.\n";


int main(void)
{
	ULONG signals;

	if (setup())
	{
		AddIntServer(INTB_VERTB, &VBInterrupt);
		SetTaskPri(mouSTerData.task, 20); 

		//PutStr("mouSTer wheel mouse driver ver:"xstr(BUILD_VERSION)" installed.\n");
		PutStr(versionString+6);
#ifdef DEBUG		
		PutStr("DEBUG build.\n"__DATE__ " " __TIME__ "\ngcc: " __VERSION__);
#endif		
	    //PutStr("press CTRL-C to exit.\n");

		while (1)
		{
			signals = Wait (mouSTerData.signal | SIGBREAKF_CTRL_C);
			if (signals & mouSTerData.signal)
			{
				while(mouSTerData.head != mouSTerData.tail)
				{


					//SendEvent(mouSTerData.cbuffer[mouSTerData.tail++]);
					newstate = mouSTerData.cbuffer[mouSTerData.tail++];
#ifdef DEBUG
					PutStr ("Got: ");
					PrintBin (newstate);
#endif
					tmp = newstate ^ laststate;

					//The interrupt routine has already verify if state is changed, so not necessary here.
					//detect and despatch events ...

					//button 4:
					tmpstate = tmp & mouSTer_protocol_button_4_mask;
					if (tmpstate)				
					{
						if (newstate & tmpstate)
						{	//button pressed
							SendEvent(NM_BUTTON_FOURTH);
						}
						else
						{	//button depressed
							SendEvent(NM_BUTTON_FOURTH | IECODE_UP_PREFIX);
						}
					}
					
					//button 5
					tmpstate = tmp & mouSTer_protocol_button_5_mask;
					if (tmpstate)				
					{
						if (newstate & tmpstate)
						{	//button pressed
							SendEvent(NM_BUTTON_FIVETH);
						}
						else
						{	//button depressed
							SendEvent(NM_BUTTON_FIVETH | IECODE_UP_PREFIX);
						}
					}

					//Wheel / vertical scroll
					tmpstate = tmp & mouSTer_protocol_wheel_Y_mask;
					if (tmpstate)				
					{
						if (((newstate & mouSTer_protocol_wheel_Y_mask) - (laststate & mouSTer_protocol_wheel_Y_mask)) & mouSTer_protocol_wheel_Y_dir_mask)
						{
							SendEvent(NM_WHEEL_DOWN);
						}
						else
						{
							SendEvent(NM_WHEEL_UP);
						}
					}

					// horizontal scroll/ac pan
					tmpstate = tmp & mouSTer_protocol_wheel_X_mask;
					if (tmpstate)				
					{
						if (((newstate & mouSTer_protocol_wheel_X_mask) - (laststate & mouSTer_protocol_wheel_X_mask)) & mouSTer_protocol_wheel_X_dir_mask)
						{
							SendEvent(NM_WHEEL_LEFT);
						}
						else
						{
							SendEvent(NM_WHEEL_RIGHT);
						}
					}

					laststate = newstate;
				}
			} 
				else 	if (signals & SIGBREAKF_CTRL_C)
			{
				PutStr("Thank You.");
				break;
			}
		}
	} 
	else 
	{
		return -1;
	}
	cleanup();
	return 0;
}


int setup ()
{
	InputMP = CreateMsgPort();
	InputIO = CreateIORequest(InputMP,sizeof(struct IOStdReq));
	OpenDevice("input.device",0,(struct IORequest *)InputIO,0);
	
	mouSTerData.task = FindTask(0);
	if (intsignal = AllocSignal (-1))
	{
		mouSTerData.signal = (1 << intsignal);
		return 1;
	}
	else
	{
		return 0;
	}

}

void cleanup()
{
	RemIntServer(INTB_VERTB, &VBInterrupt);
	FreeSignal(intsignal);
	return;
}

void SendEvent(UWORD event)
{
	MouseEvent.ie_Code = event;
	InputIO->io_Data = (APTR)&MouseEvent;
	InputIO->io_Length = sizeof(struct InputEvent);
	InputIO->io_Command = IND_WRITEEVENT;

	DoIO((struct IORequest *)InputIO);
}

#ifdef DEBUG
void PrintBin(UBYTE i)
{ //simple debug ...
	if ((i >> 7) & 1)
		PutStr("1");
	else
		PutStr("0");

	if ((i >> 6) & 1)
		PutStr("1");
	else
		PutStr("0");

	if ((i >> 5) & 1)
		PutStr("1");
	else
		PutStr("0");

	if ((i >> 4) & 1)
		PutStr("1");
	else
		PutStr("0");

	if ((i >> 3) & 1)
		PutStr("1");
	else
		PutStr("0");

	if ((i >> 2) & 1)
		PutStr("1");
	else
		PutStr("0");

	if ((i >> 1) & 1)
		PutStr("1");
	else
		PutStr("0");

	if ((i >> 0) & 1)
		PutStr("1\n");
	else
		PutStr("0\n");
}
#endif
