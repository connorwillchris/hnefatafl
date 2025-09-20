#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BOARD_SIZE 11
#define HALF_BOARD_SIZE 5

const int board_len = BOARD_SIZE * BOARD_SIZE;

void init_board(char* board) {
	memset(board, '-', board_len);

	// KING
	board[BOARD_SIZE * HALF_BOARD_SIZE + HALF_BOARD_SIZE] = 'K';

	// MIDDLE ROWS
	board[BOARD_SIZE * 4 + HALF_BOARD_SIZE] = 'x';
	board[BOARD_SIZE * HALF_BOARD_SIZE + 4] = 'x';
	board[BOARD_SIZE * HALF_BOARD_SIZE + 6] = 'x';
	board[BOARD_SIZE * 6 + HALF_BOARD_SIZE] = 'x';

	board[BOARD_SIZE * 3 + HALF_BOARD_SIZE] = 'x';
	board[BOARD_SIZE * 4 + 4] = 'x';
	board[BOARD_SIZE * 4 + 6] = 'x';
	board[BOARD_SIZE * HALF_BOARD_SIZE + 3] = 'x';
	board[BOARD_SIZE * HALF_BOARD_SIZE + 7] = 'x';
	board[BOARD_SIZE * HALF_BOARD_SIZE + 15] = 'x';
	board[BOARD_SIZE * HALF_BOARD_SIZE + 17] = 'x';
	board[BOARD_SIZE * HALF_BOARD_SIZE + BOARD_SIZE + 16] = 'x';

	// top row
	for (int i = 0; i < 5; i++) board[i + 3] = 'O';
	board[BOARD_SIZE * 1 + HALF_BOARD_SIZE] = 'O';

	// bottom row
	for (int i = 0; i < 5; i++) board[(board_len - BOARD_SIZE) + i + 3] = 'O';
	board[board_len - BOARD_SIZE * 2 + HALF_BOARD_SIZE] = 'O';

	// left row
	for (int i = 0; i < 5; i++) board[BOARD_SIZE * (i + 3)] = 'O';
	board[BOARD_SIZE * 5 + 1] = 'O';

	// right row
	for (int i = 0; i < 5; i++) board[BOARD_SIZE * (i + HALF_BOARD_SIZE - 1) - 1] = 'O';
	board[BOARD_SIZE * 4] = 'O';
}

void print_board(char* board) {

	for (int y = 0; y < BOARD_SIZE; y++) {
		for (int x = 0; x < BOARD_SIZE; x++) {
			printf(" %c", board[x + y * BOARD_SIZE]);

			if ((x % BOARD_SIZE) == BOARD_SIZE - 1) {
				printf("\n");
			}
		}
	}
}

int main(void) {
	char board[board_len];
	init_board(board);

	print_board(board);

	return 0;
}
