class main2{
	public static void main(String [] args){
		int result = (new lib()).two(5, 7);
	}
}

class lib{

	public int one(int a){
		System.out.println(a);
		return 0;
	}

	public int two(int a, int b){
		System.out.println(a+b);
		return 0;
	}
}
		
