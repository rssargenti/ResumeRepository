import javax.swing.*;
import java.sql.*;
import java.util.ArrayList;
import java.util.Scanner;

/**
 * @author Rudolph Sargenti
 *
 * -----------------------------------------INSTRUCTIONS:---------------------------------------------------------
 * 1) Change the String dbURL to whatever server you are using (I reccomend your docker container)
 *
 * 2) Correct the user (username) and pass (password)
 *
 * 3) There are no GO statements allowed. If you have a GO statement, you must remove it before inputting.
 *
 * 4) when you run the program, it will ask you how many DB commands you wish to input. DB commands are any code
 *    that does not return a result, like function calls and "drop if exists". After copying/pasting in your input,
 *    enter, then type "terminate", then enter again. Do this for each DB command.
 *
 *    Example with two DB commands:
 *
 *    DROP IF EXISTS dbo.function
 *    terminate
 *    CREATE FUNCTION dbo.function(....)
 *    AS
 *    ......
 *    ......
 *    .....
 *    END
 *    terminate
 *
 * 5) After you are finished entering your commands, it will ask you how many queries you wish to enter. Queries are
 *    any command that returns a result set (columns and rows). Same as above, copy/paste your queries into the console,
 *    hit enter, "terminate", then enter again.
 *
 *    Example with one query:
 *
 *    Use Northwinds2020TSQLV6
 *    SELECT CustomerId, CustomerCountry
 *    FROM Sales.Customer
 *    Terminate
 *
 *
 */
public class JdbcSQLServerConnection {


    public static void main(String[] args) {

        Connection conn = null;
        Scanner scnr = new Scanner(System.in);

        try {

            String dbURL = "CHANGE";
            String user = "CHANGE";
            String pass = "CHANGE";
            conn = DriverManager.getConnection(dbURL, user, pass);
            if (conn != null) {
                System.out.println("Connection Successful.\n");


                //Query caller
                try {
                    System.out.println("How many DB commands will you enter? (ie, create/drop function)");
                    int objCount = scnr.nextInt();
                    scnr.nextLine();

                    if(objCount > 0) {


                        for (int i = 0; i < objCount; i++) {
                            System.out.println("Enter DB command "+(i+1)+":");
                            StringBuilder sb = new StringBuilder();
                            Statement stmt = null;
                            stmt = conn.createStatement();
                            while(!scnr.hasNext("terminate")){
                                sb.append(scnr.nextLine()+"\n");
                            }
                            if(i != objCount-1)
                                scnr.next();
                            String command = sb.toString();
                            stmt.execute(command);
                        }
                        scnr.next();
                    }

                    System.out.println("Enter how many queries you want to print:");
                    int queryCount = scnr.nextInt();
                    scnr.nextLine(); //fixes error with scnr.nextLine() in for loop below

                    System.out.println("Enter how many rows there are in the table:");
                    int inputRowNum = scnr.nextInt()+2;
                    scnr.nextLine();

                    //Holds query results
                    ArrayList<ResultSet> rsList = new ArrayList<>();

                    //Takes in 9 queries, stores their results in rsList
                    for(int i = 0; i < queryCount; i++){
                        System.out.println("Enter Query "+(i+1)+":");
                        StringBuilder sb = new StringBuilder();
                        Statement stmt = null;
                        ResultSet rs = null;
                        stmt = conn.createStatement();
                       while(!scnr.hasNext("terminate")){
                            sb.append(scnr.nextLine()+"\n");
                        }
                        String query = sb.toString();
                        rs = stmt.executeQuery(query);
                        if(rs != null)
                        rsList.add(rs);
                    }
                    //initialize JFrame
                    JFrame frame = new JFrame();
                    frame.setTitle("Queries");
                    frame.setSize(200, 500);
                    JScrollPane sp;

                    //adds each column from rsList into a JTable
                   for(int x = 0; x < rsList.size(); x++){
                       ResultSetMetaData data = rsList.get(x).getMetaData();
                       int columnCount = data.getColumnCount();
                       int rowCount = 0;


                       JTable table = new JTable(inputRowNum,columnCount);
                       table.setBounds(30,40,200,300);
                       sp = new JScrollPane(table);

                       //print column titles
                       for(int i = 0; i < columnCount; i++){
                           table.setValueAt(data.getColumnLabel(i+1), 0, i);//TODO FIX THIS
                       }

                       //System.out.println();

                       //print column values
                       int j = 1;
                       while(rsList.get(x).next() && j < inputRowNum){
                           for(int i = 0; i < columnCount; i++){
                               table.setValueAt(rsList.get(x).getString(i+1), j, i);
                           }
                           j++;
                           //System.out.println();
                           rowCount++;
                       }
                       frame.add(sp);
                       frame.setVisible(true);
                       System.out.println(rowCount+" rows affected");
                   }



                }
                catch(SQLException ex){
                    System.out.println("SQL EXCEPTION: "+ex.getMessage());
                    System.out.println("SQLState: " + ex.getSQLState());
                    System.out.println("VendorError: " + ex.getErrorCode());
                }

            }

        } catch (SQLException ex) {
            ex.printStackTrace();
        } finally {
            try {
                if (conn != null && !conn.isClosed()) {
                    conn.close();
                }
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }
    }
}
