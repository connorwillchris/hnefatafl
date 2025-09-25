#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define BOARD_SIZE 11
#define HALF_BOARD_SIZE 5

const int board_len = BOARD_SIZE * BOARD_SIZE;

// helper function
inline int vec_to_pos(int x, int y) {
	return x * BOARD_SIZE + y;
}

// not greatly optimized, might change later
void init_board(
	char* board,
	int* white_pieces,
	int* black_pieces,
	int* king_piece
) {
	memset(board, '.', board_len);

	king_piece[0] = vec_to_pos(HALF_BOARD_SIZE, HALF_BOARD_SIZE);
}

// helper function
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

void get_input(char* i) {
	fgets(i, 80, stdin);
}

int main(void) {
	char board[board_len];
	
	int white_pieces[24];
	int black_pieces[11];
	int king_piece[1];

	char input[80];

	init_board(board, white_pieces, black_pieces, king_piece);
	print_board(board);

	bool loop = true;

	return 0;
}
