from flask import Flask, request, render_template_string
import sqlite3
import hashlib

app = Flask(__name__)

def get_targeted_user(query, username_input):
    """Determine which user is being targeted by the injection"""
    # List of corporate users to check for targeting
    corporate_users = ['asmith', 'mjohnson', 'lgarcia', 'dwilson', 
                                             'swilliams', 'rdavis', 'kmiller', 'bthompson', 
                       'canderson', 'tbrown']
    
    # Check if the injection specifically targets a user in the username field
    for user in corporate_users:
        if user in username_input.lower():
            return user
    
    # Check if UNION injection targets a specific user
    if "union" in query.lower():
        for user in corporate_users:
            if user in query.lower():
                return user
    
    return None

def is_data_extraction(query, results):
    """Check if this injection successfully extracted employee data"""
    # Any injection that returns employee data should get the flag
    injection_indicators = [
        "union" in query.lower(),
        "or" in query.lower() and ("1=1" in query.lower() or "true" in query.lower()),
        "--" in query.lower(),
        "'" in query and len(query.split("'")) > 2
    ]
    
    # If it looks like injection AND returned data, it's successful
    return any(injection_indicators) and results and len(results) > 0

@app.route("/")
def index():
    return render_template_string("""
        <h2>TechCorp Internal Portal</h2>
        <p><a href="/login">Employee Access Login</a></p>
        <p><small>For TechCorp employees only - Unauthorized access prohibited</small></p>
        <hr>
        <p><em>TechCorp Employee Directory System</em></p>
    """)

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "")
        password = request.form.get("password", "")
        
        # Corporate employee lookup query
        query = f"SELECT username || '|' || password_hash || '|' || department FROM employees WHERE username='{username}' AND password_hash='{password}';"
        
        try:
            conn = sqlite3.connect("/opt/ctf/data/users.db")
            cursor = conn.cursor()
            
            cursor.execute(query)
            all_results = cursor.fetchall()
            
            conn.close()

            if all_results:
                # Check if this is a targeted injection
                targeted_user = get_targeted_user(query, username)
                
                if targeted_user:
                    # Return only the targeted user's data
                    for result in all_results:
                        if targeted_user in result[0]:
                            response = f"<p style='color:green;'>Employee authentication successful!</p>\n"
                            response += f"<p><strong>Employee Data:</strong> {result[0]}</p>\n"
                            
                            # Give flag for successful targeted injection
                            if is_data_extraction(query, all_results):
                                flag_content = "FLAG3_PLACEHOLDER"
                                response += f"<hr><p style='color:orange;'><strong>SYSTEM DEBUG:</strong> Data access logged!</p>\n"
                                response += f"<p style='color:orange;'><strong>Employee Database Breach Flag:</strong> {flag_content}</p>\n"
                                response += f"<p style='color:orange;'><em>Note: This flag represents successful database compromise (same for all accounts)</em></p>\n"
                            
                            return response
                    
                    # If targeted user not found in results, show error
                    return f"<p style='color:red;'>Employee not found in directory.</p>\n", 401
                else:
                    # Generic injection - return first result but indicate it's limited
                    response = f"<p style='color:green;'>Employee authentication successful!</p>\n"
                    response += f"<p><strong>Employee Data:</strong> {all_results[0][0]}</p>\n"
                    
                    # Give flag for any successful injection
                    if is_data_extraction(query, all_results):
                        flag_content = "FLAG3_PLACEHOLDER"
                        response += f"<hr><p style='color:orange;'><strong>SYSTEM DEBUG:</strong> Data access logged!</p>\n"
                        response += f"<p style='color:orange;'><strong>Employee Database Breach Flag:</strong> {flag_content}</p>\n"
                        response += f"<p style='color:orange;'><em>Note: This flag represents successful database compromise (same for all accounts)</em></p>\n"
                    
                    return response
            else:
                return f"<p style='color:red;'>Invalid employee credentials.</p>\n", 401
        except Exception as e:
            return f"<p style='color:red;'>Database Error: {e}</p>\n", 500

    return render_template_string("""
        <h2>TechCorp Employee Login</h2>
        <form method="POST">
            Username: <input type="text" name="username" placeholder="username"><br><br>
            Password Hash: <input type="password" name="password" placeholder="Enter MD5 hash"><br><br>
            <input type="submit" value="Authenticate">
        </form>
        <hr>
        <p><small>Employee Directory Access</small></p>
        <p><small>Use your corporate username and password</small></p>
    """)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
