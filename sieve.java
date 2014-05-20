class Main{
	public static void main(String[] args){
		int tmp = 0;
		History h = new History();
		tmp = h.add(2);
		System.out.println(2);

		int i = 3;
		while(true){
			if(h.check(i)){
				tmp = h.add(i);
				System.out.println(i);
			}else{}
			i = i + 1;
		}
	}
}

class History{
	int thisValue;
	History next;

	public int add(int value){
		int tmp = 0;
		if(thisValue == 0)
			thisValue = value;
		else{
			if(next == null)
				next = new History();
			else{}

			tmp = next.add(value);
		}

		return value;
	}

	public boolean check(int value){
		return (((value/thisValue) * thisValue) != value) && ( (next == null) || (next.check(value)) );
	}
}




