export interface SBC {
	id: string;
	name: string;
	manufacturer: string;
	compatibleBoards: string[];
	documentationLink?: string;
}

export const BTT_CB1: SBC = {
	id: 'btt-cb1',
	name: 'BTT CB1',
	manufacturer: 'BIGTREETECH',
	compatibleBoards: ['btt-manta-m4p', 'btt-manta-m8p-11', 'btt-manta-m8p-20'],
	documentationLink: 'https://os.ratrig.com/docs/boards/btt/cb1',
};

export const BTT_CB2: SBC = {
	id: 'btt-cb2',
	name: 'BTT CB2',
	manufacturer: 'BIGTREETECH',
	compatibleBoards: ['btt-manta-m4p', 'btt-manta-m8p-11', 'btt-manta-m8p-20'],
	documentationLink: 'https://os.ratrig.com/docs/boards/btt/cb2',
};

export const SBCS: SBC[] = [BTT_CB1, BTT_CB2];
