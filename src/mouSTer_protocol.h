/* 
 * File:   mouSTer_protocol.h
 * Author: willy
 *
 */

#ifndef MOUSTER_PROTOCOL
#define MOUSTER_PROTOCOL


#define mouSTer_protocol_data_mask      0b01111111

#define mouSTer_protocol_parity         0b00000001
#define mouSTer_protocol_parity_mask    0b01000000
#define mouSTer_protocol_parity_pos     6


#define mouSTer_protocol_wheel_Y_mask   0b00000011
#define mouSTer_protocol_wheel_Y_pos    0
#define mouSTer_protocol_wheel_Y_dir_mask 0b000010

#define mouSTer_protocol_wheel_X_mask   0b00001100
#define mouSTer_protocol_wheel_X_pos    2
#define mouSTer_protocol_wheel_X_dir_mask 0b001000

#define mouSTer_protocol_button_4_mask  0b00010000
#define mouSTer_protocol_button_4_pos   4

#define mouSTer_protocol_button_5_mask  0b00100000
#define mouSTer_protocol_button_5_pos   5

#endif /* MOUSTER_PROTOCOL */