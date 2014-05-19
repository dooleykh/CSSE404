class Main {
	public static void main(String[] argv) {
		System.out.println(-1+(8-3*5)/3);
		int a = 8;
		int b = 3;
		System.out.println(a/b);
		System.out.println(-1+(a-b*5)/3);
		while (a >= b) {
			a = a * 2;
			b = b * 3;
			System.out.println(a);
			System.out.println(b);
		}
	}
}
