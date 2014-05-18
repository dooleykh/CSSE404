class main2{
	public static void main(String[] args){
		lib one = new lib();
		int b = one.thing();
		b = one.thing();
		b = one.thing();

		lib two = new lib();
		b = two.thing();
		b = two.thing();
		b = one.thing();
		b = two.thing();

		lib2 three = new lib2();
		b = three.thing();

	}
}

class lib extends main2{
	int a;

	public int thing(){
		a = a + 1;
		System.out.println(a);
		return 0;
	}
}

class lib2 extends lib{
}
