class mainclass {
    public static void main(String[] ID) {
        
    }
}

class c extends mainclass {
    int a;
    public boolean function() {
        return true;
    }
    public int fun() {
        return this.function();
    }
}

class d extends c{
    public int fun() {
        return 2;
    }
}
