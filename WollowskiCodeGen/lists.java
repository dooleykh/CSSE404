class Main {
	public static void main(String[] args) {
		LinkedList root = new LinkedList();
		int waste = root.initialize();

		IterLoop it = new IterLoop();
		waste = it.creator(3, root);
		waste = it.printor(3, root);
		
	}
}

class INeedAForLoop {
	
	public int f(int n) {
		return 2;
	}
	
	public int creator(int n, LinkedList root) {
		if(n >= 0) {
			int waste = root.set(n, this.f(n));
			waste = this.creator(n - 1, root);
		} else {}
		return 0;
	}
	
	public int printor(int n, LinkedList root) {
		if(n >= 0) {
			System.out.println(root.get(n));
			int waste = this.printor(n - 1, root);
		} else {}
		return 0;
	}
}

class IterLoop extends INeedAForLoop{
	public int f(int n){
		return n;
	}
}

class LinkedList {
	int here;
	LinkedList next;
	boolean nextExists;

	// My own constructor contract
	public int initialize() {
		here = 0;
		next = null;
		return 1;
	}
	
	public int set(int index, int value) {
		int result = 0;
		if(index == 0) {
			here = value;
			result = value;
		} else {
			// Dynamic expansion
			if(next != null) {
				result = next.set(index - 1, value);
			} else {
				next = new LinkedList();
				int waste = next.initialize();
				result = next.set(index - 1, value);
			}
		}
		return result;
	}
	
	public int get(int index) {
		int result = 0;
		if(index == 0) {
			result = here;
		} else {
			if(next != null) 
				result = next.get(index - 1);
			else {
				int waste = 0;
			}
		}
		return result;
	}	
}
